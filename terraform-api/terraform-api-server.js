const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const { 
  S3Client, 
  PutObjectCommand, 
  DeleteObjectCommand, 
  ListObjectsV2Command, 
  DeleteBucketCommand,
  CreateBucketCommand,
  HeadBucketCommand,
  ListBucketsCommand,
  GetObjectCommand
} = require('@aws-sdk/client-s3');
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');

const app = express();
const port = process.env.PORT || 3000;
const terraformPath = process.env.TERRAFORM_PATH || '/Users/jasmyelzhamathew/terraform-ec2-web-app';
const s3Region = process.env.AWS_REGION || 'us-east-1';

// AWS S3 Client
const s3Client = new S3Client({ region: s3Region });

// Single S3 bucket for all templates
let s3BucketName = null;

// Keep track of all created buckets
const createdBuckets = new Set();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Generate a unique bucket name
function generateBucketName() {
  const timestamp = Date.now();
  const randomString = crypto.randomBytes(4).toString('hex');
  return `terraform-temp-${timestamp}-${randomString}`;
}

// Find all temporary buckets created by this API
async function findAllTemporaryBuckets() {
  try {
    const { Buckets } = await s3Client.send(new ListBucketsCommand({}));
    if (!Buckets || Buckets.length === 0) {
      return [];
    }
    
    const tempBuckets = Buckets.filter(bucket => 
      bucket.Name.startsWith('terraform-temp-') || 
      bucket.Name.startsWith('terraform-state-')
    );
    
    return tempBuckets.map(bucket => bucket.Name);
  } catch (error) {
    console.error('Error finding temporary buckets:', error);
    return [];
  }
}

// Clean up all temporary buckets
async function cleanupAllBuckets() {
  try {
    // Find all buckets matching our pattern
    const bucketsToDelete = await findAllTemporaryBuckets();
    
    // Also include any buckets we've tracked in this session
    createdBuckets.forEach(bucket => {
      if (!bucketsToDelete.includes(bucket)) {
        bucketsToDelete.push(bucket);
      }
    });
    
    console.log(`Found ${bucketsToDelete.length} temporary buckets to delete`);
    
    let deletedCount = 0;
    for (const bucketName of bucketsToDelete) {
      try {
        // Empty the bucket first
        const { Contents } = await s3Client.send(new ListObjectsV2Command({ Bucket: bucketName }));
        
        if (Contents && Contents.length > 0) {
          for (const obj of Contents) {
            await s3Client.send(new DeleteObjectCommand({ 
              Bucket: bucketName, 
              Key: obj.Key 
            }));
            console.log(`Deleted object ${obj.Key} from bucket ${bucketName}`);
          }
        }
        
        // Delete the bucket
        console.log(`Deleting S3 bucket: ${bucketName}`);
        await s3Client.send(new DeleteBucketCommand({ Bucket: bucketName }));
        
        // Remove from our tracked list
        createdBuckets.delete(bucketName);
        s3BucketName = null;
        
        deletedCount++;
      } catch (error) {
        console.error(`Error deleting bucket ${bucketName}:`, error);
      }
    }
    
    return {
      success: true,
      total: bucketsToDelete.length,
      deleted: deletedCount
    };
  } catch (error) {
    console.error('Error cleaning up buckets:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

// Create S3 bucket for temporary storage if it doesn't exist
async function ensureS3Bucket() {
  if (!s3BucketName) {
    s3BucketName = generateBucketName();
    try {
      console.log(`Creating S3 bucket: ${s3BucketName}`);
      await s3Client.send(new CreateBucketCommand({
        Bucket: s3BucketName,
        CreateBucketConfiguration: s3Region !== 'us-east-1' ? { LocationConstraint: s3Region } : undefined
      }));
      console.log(`Successfully created bucket: ${s3BucketName}`);
      
      // Track this bucket
      createdBuckets.add(s3BucketName);
    } catch (error) {
      console.error(`Error creating S3 bucket ${s3BucketName}:`, error);
      throw error;
    }
  } else {
    // Check if bucket exists
    try {
      await s3Client.send(new HeadBucketCommand({ Bucket: s3BucketName }));
    } catch (error) {
      if (error.name === 'NotFound' || error.name === 'NoSuchBucket') {
        // Bucket doesn't exist, create it
        s3BucketName = generateBucketName();
        await s3Client.send(new CreateBucketCommand({
          Bucket: s3BucketName,
          CreateBucketConfiguration: s3Region !== 'us-east-1' ? { LocationConstraint: s3Region } : undefined
        }));
        
        // Track this bucket
        createdBuckets.add(s3BucketName);
      } else {
        throw error;
      }
    }
  }
  return s3BucketName;
}

// Upload state files to S3
async function uploadStateToS3(templateName) {
  try {
    const bucketName = await ensureS3Bucket();
    const stateFiles = fs.readdirSync(terraformPath).filter(file => file.includes('.tfstate'));
    
    for (const stateFile of stateFiles) {
      const fileContent = fs.readFileSync(path.join(terraformPath, stateFile));
      
      await s3Client.send(new PutObjectCommand({
        Bucket: bucketName,
        Key: `${templateName}/${stateFile}`,
        Body: fileContent
      }));
      
      console.log(`Uploaded ${stateFile} for ${templateName} to ${bucketName}`);
    }
    
    return bucketName;
  } catch (error) {
    console.error(`Error uploading state to S3:`, error);
    throw error;
  }
}

// Download state files from S3
async function downloadStateFromS3(templateName) {
  if (!s3BucketName) {
    return false; // No bucket exists yet
  }
  
  try {
    const prefix = `${templateName}/`;
    const { Contents } = await s3Client.send(new ListObjectsV2Command({ 
      Bucket: s3BucketName,
      Prefix: prefix
    }));
    
    if (!Contents || Contents.length === 0) {
      return false; // No state files for this template
    }
    
    for (const obj of Contents) {
      const { Body } = await s3Client.send(new GetObjectCommand({
        Bucket: s3BucketName,
        Key: obj.Key
      }));
      
      let streamData = Buffer.from([]);
      
      for await (const chunk of Body) {
        streamData = Buffer.concat([streamData, chunk]);
      }
      
      const fileName = path.basename(obj.Key);
      await fs.promises.writeFile(path.join(terraformPath, fileName), streamData);
      console.log(`Downloaded ${fileName} for template ${templateName}`);
    }
    
    return true;
  } catch (error) {
    console.error(`Error downloading state from S3:`, error);
    return false;
  }
}

// Delete template state from S3
async function deleteTemplateFromS3(templateName) {
  if (!s3BucketName) {
    return false;
  }
  
  try {
    const prefix = `${templateName}/`;
    const { Contents } = await s3Client.send(new ListObjectsV2Command({ 
      Bucket: s3BucketName,
      Prefix: prefix
    }));
    
    if (!Contents || Contents.length === 0) {
      return false;
    }
    
    for (const obj of Contents) {
      await s3Client.send(new DeleteObjectCommand({
        Bucket: s3BucketName,
        Key: obj.Key
      }));
      console.log(`Deleted ${obj.Key} from bucket ${s3BucketName}`);
    }
    
    return true;
  } catch (error) {
    console.error(`Error deleting template from S3:`, error);
    return false;
  }
}

// Function to execute Terraform commands
function runTerraformCommand(command, args = []) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(terraformPath)) {
      return reject(`Terraform project path not found: ${terraformPath}`);
    }
    
    console.log(`Running terraform ${command} in ${terraformPath}`);
    
    const terraform = spawn('terraform', [command, ...args], {
      cwd: terraformPath,
      shell: true,
    });
    
    let output = '';
    let errorOutput = '';
    
    terraform.stdout.on('data', (data) => {
      const chunk = data.toString();
      output += chunk;
      console.log(chunk);
    });
    
    terraform.stderr.on('data', (data) => {
      const chunk = data.toString();
      errorOutput += chunk;
      console.error(chunk);
    });
    
    terraform.on('close', (code) => {
      if (code !== 0) {
        reject({
          success: false,
          command: `terraform ${command}`,
          code,
          output,
          error: errorOutput,
        });
      } else {
        resolve({
          success: true,
          command: `terraform ${command}`,
          output,
        });
      }
    });
    
    terraform.on('error', (err) => {
      reject({
        success: false,
        command: `terraform ${command}`,
        error: err.message,
      });
    });
  });
}

// Modify Terraform files to use local state
async function prepareLocalState() {
  try {
    const mainTfPath = path.join(terraformPath, 'main.tf');
    
    if (fs.existsSync(mainTfPath)) {
      let content = fs.readFileSync(mainTfPath, 'utf8');
      
      // Simple regex to comment out S3 backend block if it exists
      const s3BackendRegex = /(terraform\s*\{[^{]*backend\s*"s3"\s*\{[^}]*\}[^}]*\})/gs;
      if (s3BackendRegex.test(content)) {
        // Comment out S3 backend block
        content = content.replace(s3BackendRegex, '/*\n$1\n*/');
        
        // Add local backend
        if (!content.includes('backend "local"')) {
          content = content.replace(
            /terraform\s*\{/,
            'terraform {\n  backend "local" {}\n'
          );
        }
        
        fs.writeFileSync(mainTfPath, content);
        console.log('Modified main.tf to use local state');
      }
    }
    
    return true;
  } catch (error) {
    console.error('Error preparing local state:', error);
    return false;
  }
}

// API Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Terraform API is running' });
});

// Template-specific init endpoint
app.post('/api/terraform/:templateName/init', async (req, res) => {
  try {
    const { templateName } = req.params;
    console.log(`Received init request for template ${templateName}`);
    
    // Prepare Terraform files to use local state
    await prepareLocalState();
    
    // Ensure we have an S3 bucket for storing state after init
    await ensureS3Bucket();
    
    // Run terraform init with local state
    const args = req.body.args || [];
    const result = await runTerraformCommand('init', args);
    
    // Upload state files to S3
    await uploadStateToS3(templateName);
    
    res.status(200).json({
      ...result,
      templateName,
      s3BucketName,
      message: `Template ${templateName} initialized successfully`
    });
  } catch (error) {
    console.error(`Error running terraform init for template ${req.params.templateName}:`, error);
    res.status(500).json({ success: false, error: error.message || JSON.stringify(error) });
  }
});

// Template-specific apply endpoint
app.post('/api/terraform/:templateName/apply', async (req, res) => {
  try {
    const { templateName } = req.params;
    console.log(`Received apply request for template ${templateName}`);
    
    // Download existing state if available
    await downloadStateFromS3(templateName);
    
    const args = req.body.args || ['-auto-approve'];
    const result = await runTerraformCommand('apply', args);
    
    // Upload updated state to S3
    await uploadStateToS3(templateName);
    
    res.status(200).json({
      ...result,
      templateName,
      s3BucketName,
      message: `Template ${templateName} applied successfully`
    });
  } catch (error) {
    console.error(`Error running terraform apply for template ${req.params.templateName}:`, error);
    res.status(500).json({ success: false, error: error.message || JSON.stringify(error) });
  }
});

// Template-specific destroy endpoint
app.post('/api/terraform/:templateName/destroy', async (req, res) => {
  try {
    const { templateName } = req.params;
    console.log(`Received destroy request for template ${templateName}`);
    
    // Download existing state if available
    await downloadStateFromS3(templateName);
    
    const args = req.body.args || ['-auto-approve'];
    const result = await runTerraformCommand('destroy', args);
    
    // Delete template state from S3
    await deleteTemplateFromS3(templateName);
    
    // Enhanced cleanup to ensure all temporary buckets are removed
    const cleanupResult = await cleanupAllBuckets();
    console.log('Cleanup result:', cleanupResult);
    
    res.status(200).json({
      ...result,
      templateName,
      message: `Template ${templateName} destroyed and resources cleaned up`,
      cleanup: cleanupResult
    });
  } catch (error) {
    console.error(`Error running terraform destroy for template ${req.params.templateName}:`, error);
    res.status(500).json({ success: false, error: error.message || JSON.stringify(error) });
  }
});

// Get S3 bucket status
app.get('/api/bucket', (req, res) => {
  res.status(200).json({
    success: true,
    s3BucketName,
    exists: s3BucketName !== null,
    allBuckets: Array.from(createdBuckets)
  });
});

// Cleanup all resources
app.post('/api/cleanup', async (req, res) => {
  try {
    const cleanupResult = await cleanupAllBuckets();
    
    res.status(200).json({
      success: cleanupResult.success,
      message: cleanupResult.success ? 
        `All resources cleaned up successfully. Deleted ${cleanupResult.deleted} of ${cleanupResult.total} buckets.` : 
        'Error cleaning up some resources',
      details: cleanupResult
    });
  } catch (error) {
    console.error('Error cleaning up resources:', error);
    res.status(500).json({ success: false, error: error.message || JSON.stringify(error) });
  }
});

// List active templates
app.get('/api/templates', async (req, res) => {
  try {
    if (!s3BucketName) {
      return res.status(200).json({
        success: true,
        templates: []
      });
    }
    
    // List all directories in the bucket (each directory represents a template)
    const { CommonPrefixes } = await s3Client.send(new ListObjectsV2Command({ 
      Bucket: s3BucketName,
      Delimiter: '/'
    }));
    
    const templates = CommonPrefixes ? 
      CommonPrefixes.map(prefix => prefix.Prefix.replace('/', '')) : 
      [];
    
    res.status(200).json({
      success: true,
      s3BucketName,
      templates
    });
  } catch (error) {
    console.error('Error listing templates:', error);
    res.status(500).json({ success: false, error: error.message || JSON.stringify(error) });
  }
});

// List all available endpoints
app.get('/', (req, res) => {
  const endpoints = [
    { method: 'GET', path: '/health', description: 'Health check' },
    { method: 'POST', path: '/api/terraform/:templateName/init', description: 'Initialize Terraform for a specific template' },
    { method: 'POST', path: '/api/terraform/:templateName/apply', description: 'Apply Terraform configuration for a specific template' },
    { method: 'POST', path: '/api/terraform/:templateName/destroy', description: 'Destroy Terraform resources for a specific template' },
    { method: 'GET', path: '/api/bucket', description: 'Get S3 bucket status' },
    { method: 'GET', path: '/api/templates', description: 'List active templates' },
    { method: 'POST', path: '/api/cleanup', description: 'Clean up all resources' }
  ];
  
  res.status(200).json({
    name: 'Terraform API Server',
    version: '1.0.0',
    terraformPath,
    s3BucketName,
    createdBuckets: Array.from(createdBuckets),
    endpoints
  });
});

// Start the server
app.listen(port, () => {
  console.log(`Terraform API server listening at http://localhost:${port}`);
  console.log(`Using Terraform project path: ${terraformPath}`);
  console.log(`Using AWS region: ${s3Region}`);
  
  // Log all available endpoints
  console.log('Available endpoints:');
  console.log('GET  /health');
  console.log('GET  /');
  console.log('POST /api/terraform/:templateName/init');
  console.log('POST /api/terraform/:templateName/apply');
  console.log('POST /api/terraform/:templateName/destroy');
  console.log('GET  /api/bucket');
  console.log('GET  /api/templates');
  console.log('POST /api/cleanup');
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  cleanupAllBuckets().then(() => {
    console.log('All buckets cleaned up during shutdown');
    process.exit(0);
  }).catch(() => {
    console.log('Error cleaning up buckets during shutdown');
    process.exit(1);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  cleanupAllBuckets().then(() => {
    console.log('All buckets cleaned up during shutdown');
    process.exit(0);
  }).catch(() => {
    console.log('Error cleaning up buckets during shutdown');
    process.exit(1);
  });
});