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

// Track template-specific buckets
const templateBuckets = new Map(); // templateName -> bucketName
const createdBuckets = new Set();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Generate a predictable bucket name based on template
function generateTemplateBucketName(templateName, environment = 'dev') {
  // Create a consistent hash for the template
  const hash = crypto.createHash('md5').update(`${templateName}-${environment}`).digest('hex').substring(0, 8);
  return `terraform-state-${templateName}-${environment}-${hash}`;
}

// Parse Terraform output to get actual bucket name
function parseTerraformOutput(output) {
  try {
    // Look for bucket name in terraform output
    const bucketMatch = output.match(/terraform_state_bucket\s*=\s*"([^"]+)"/);
    if (bucketMatch) {
      return bucketMatch[1];
    }
    
    // Alternative patterns
    const altMatch = output.match(/bucket[^=]*=\s*"([^"]+)"/i);
    if (altMatch) {
      return altMatch[1];
    }
    
    return null;
  } catch (error) {
    console.error('Error parsing terraform output:', error);
    return null;
  }
}

// Get or create bucket for template
async function getTemplateBucket(templateName, environment = 'dev') {
  // Check if we already have a bucket for this template
  if (templateBuckets.has(templateName)) {
    const bucketName = templateBuckets.get(templateName);
    try {
      await s3Client.send(new HeadBucketCommand({ Bucket: bucketName }));
      return bucketName;
    } catch (error) {
      console.log(`Bucket ${bucketName} no longer exists, will create new one`);
      templateBuckets.delete(templateName);
    }
  }
  
  // Generate predictable bucket name
  const bucketName = generateTemplateBucketName(templateName, environment);
  
  try {
    // Check if bucket exists
    await s3Client.send(new HeadBucketCommand({ Bucket: bucketName }));
    console.log(`Found existing bucket: ${bucketName}`);
  } catch (error) {
    if (error.name === 'NotFound' || error.name === 'NoSuchBucket') {
      // Create the bucket
      console.log(`Creating bucket: ${bucketName}`);
      await s3Client.send(new CreateBucketCommand({
        Bucket: bucketName,
        CreateBucketConfiguration: s3Region !== 'us-east-1' ? { LocationConstraint: s3Region } : undefined
      }));
      console.log(`Successfully created bucket: ${bucketName}`);
    } else {
      throw error;
    }
  }
  
  // Track the bucket
  templateBuckets.set(templateName, bucketName);
  createdBuckets.add(bucketName);
  
  return bucketName;
}

// Find all terraform-related buckets
async function findAllTerraformBuckets() {
  try {
    const { Buckets } = await s3Client.send(new ListBucketsCommand({}));
    if (!Buckets || Buckets.length === 0) {
      return [];
    }
    
    const terraformBuckets = Buckets.filter(bucket => 
      bucket.Name.startsWith('terraform-state-') || 
      bucket.Name.startsWith('terraform-temp-')
    );
    
    return terraformBuckets.map(bucket => bucket.Name);
  } catch (error) {
    console.error('Error finding terraform buckets:', error);
    return [];
  }
}

// Clean up bucket contents and delete bucket
async function cleanupBucket(bucketName) {
  try {
    console.log(`Cleaning up bucket: ${bucketName}`);
    
    // List and delete all objects
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
    await s3Client.send(new DeleteBucketCommand({ Bucket: bucketName }));
    console.log(`Successfully deleted bucket: ${bucketName}`);
    
    return true;
  } catch (error) {
    console.error(`Error cleaning up bucket ${bucketName}:`, error);
    return false;
  }
}

// Clean up all terraform buckets
async function cleanupAllBuckets() {
  try {
    const bucketsToDelete = await findAllTerraformBuckets();
    
    // Add tracked buckets
    createdBuckets.forEach(bucket => {
      if (!bucketsToDelete.includes(bucket)) {
        bucketsToDelete.push(bucket);
      }
    });
    
    console.log(`Found ${bucketsToDelete.length} terraform buckets to clean up`);
    
    let deletedCount = 0;
    for (const bucketName of bucketsToDelete) {
      const success = await cleanupBucket(bucketName);
      if (success) {
        deletedCount++;
        createdBuckets.delete(bucketName);
        
        // Remove from template mapping
        for (const [template, bucket] of templateBuckets.entries()) {
          if (bucket === bucketName) {
            templateBuckets.delete(template);
            break;
          }
        }
      }
    }
    
    return {
      success: true,
      total: bucketsToDelete.length,
      deleted: deletedCount
    };
  } catch (error) {
    console.error('Error in cleanup process:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

// Upload state files to S3
async function uploadStateToS3(templateName, bucketName) {
  try {
    const stateFiles = fs.readdirSync(terraformPath).filter(file => 
      file.includes('.tfstate') || file === 'terraform.tfstate'
    );
    
    for (const stateFile of stateFiles) {
      const filePath = path.join(terraformPath, stateFile);
      if (fs.existsSync(filePath)) {
        const fileContent = fs.readFileSync(filePath);
        
        await s3Client.send(new PutObjectCommand({
          Bucket: bucketName,
          Key: `${templateName}/${stateFile}`,
          Body: fileContent
        }));
        
        console.log(`Uploaded ${stateFile} for ${templateName} to ${bucketName}`);
      }
    }
    
    return true;
  } catch (error) {
    console.error(`Error uploading state to S3:`, error);
    throw error;
  }
}

// Download state files from S3
async function downloadStateFromS3(templateName, bucketName) {
  try {
    const prefix = `${templateName}/`;
    const { Contents } = await s3Client.send(new ListObjectsV2Command({ 
      Bucket: bucketName,
      Prefix: prefix
    }));
    
    if (!Contents || Contents.length === 0) {
      console.log(`No state files found for template ${templateName}`);
      return false;
    }
    
    for (const obj of Contents) {
      const { Body } = await s3Client.send(new GetObjectCommand({
        Bucket: bucketName,
        Key: obj.Key
      }));
      
      let streamData = Buffer.from([]);
      for await (const chunk of Body) {
        streamData = Buffer.concat([streamData, chunk]);
      }
      
      const fileName = path.basename(obj.Key);
      const filePath = path.join(terraformPath, fileName);
      await fs.promises.writeFile(filePath, streamData);
      console.log(`Downloaded ${fileName} for template ${templateName}`);
    }
    
    return true;
  } catch (error) {
    console.error(`Error downloading state from S3:`, error);
    return false;
  }
}

// Delete template state from S3
async function deleteTemplateFromS3(templateName, bucketName) {
  try {
    const prefix = `${templateName}/`;
    const { Contents } = await s3Client.send(new ListObjectsV2Command({ 
      Bucket: bucketName,
      Prefix: prefix
    }));
    
    if (!Contents || Contents.length === 0) {
      return false;
    }
    
    for (const obj of Contents) {
      await s3Client.send(new DeleteObjectCommand({
        Bucket: bucketName,
        Key: obj.Key
      }));
      console.log(`Deleted ${obj.Key} from bucket ${bucketName}`);
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
    
    console.log(`Running terraform ${command} ${args.join(' ')} in ${terraformPath}`);
    
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

// API Routes

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    message: 'Terraform API is running',
    activeTemplates: Array.from(templateBuckets.keys()),
    trackedBuckets: Array.from(createdBuckets)
  });
});

// Template-specific init endpoint
app.post('/api/terraform/:templateName/init', async (req, res) => {
  try {
    const { templateName } = req.params;
    const { environment = 'dev' } = req.body;
    
    console.log(`Initializing template ${templateName} for environment ${environment}`);
    
    // Get or create bucket for this template
    const bucketName = await getTemplateBucket(templateName, environment);
    
    // Run terraform init
    const args = req.body.args || [];
    const result = await runTerraformCommand('init', args);
    
    // Upload initial state
    await uploadStateToS3(templateName, bucketName);
    
    res.status(200).json({
      ...result,
      templateName,
      environment,
      bucketName,
      message: `Template ${templateName} initialized successfully`
    });
  } catch (error) {
    console.error(`Error initializing template ${req.params.templateName}:`, error);
    res.status(500).json({ 
      success: false, 
      error: error.message || JSON.stringify(error),
      templateName: req.params.templateName
    });
  }
});

// Template-specific apply endpoint
app.post('/api/terraform/:templateName/apply', async (req, res) => {
  try {
    const { templateName } = req.params;
    const { environment = 'dev' } = req.body;
    
    console.log(`Applying template ${templateName} for environment ${environment}`);
    
    // Get bucket for this template
    const bucketName = await getTemplateBucket(templateName, environment);
    
    // Download existing state
    await downloadStateFromS3(templateName, bucketName);
    
    // Run terraform apply
    const args = req.body.args || ['-auto-approve'];
    const result = await runTerraformCommand('apply', args);
    
    // Parse output to get actual bucket name created by Terraform
    const actualBucketName = parseTerraformOutput(result.output);
    if (actualBucketName && actualBucketName !== bucketName) {
      console.log(`Terraform created bucket: ${actualBucketName}, updating tracking`);
      templateBuckets.set(templateName, actualBucketName);
      createdBuckets.add(actualBucketName);
    }
    
    // Upload updated state
    await uploadStateToS3(templateName, bucketName);
    
    res.status(200).json({
      ...result,
      templateName,
      environment,
      bucketName,
      actualBucketName,
      message: `Template ${templateName} applied successfully`
    });
  } catch (error) {
    console.error(`Error applying template ${req.params.templateName}:`, error);
    res.status(500).json({ 
      success: false, 
      error: error.message || JSON.stringify(error),
      templateName: req.params.templateName
    });
  }
});

// Template-specific destroy endpoint
app.post('/api/terraform/:templateName/destroy', async (req, res) => {
  try {
    const { templateName } = req.params;
    const { environment = 'dev' } = req.body;
    
    console.log(`Destroying template ${templateName} for environment ${environment}`);
    
    // Get bucket for this template
    const bucketName = await getTemplateBucket(templateName, environment);
    
    // Download existing state
    await downloadStateFromS3(templateName, bucketName);
    
    // Run terraform destroy
    const args = req.body.args || ['-auto-approve'];
    const result = await runTerraformCommand('destroy', args);
    
    // Clean up template state from S3
    await deleteTemplateFromS3(templateName, bucketName);
    
    // Clean up the bucket itself
    await cleanupBucket(bucketName);
    
    // Remove from tracking
    templateBuckets.delete(templateName);
    createdBuckets.delete(bucketName);
    
    res.status(200).json({
      ...result,
      templateName,
      environment,
      bucketName,
      message: `Template ${templateName} destroyed and cleaned up successfully`
    });
  } catch (error) {
    console.error(`Error destroying template ${req.params.templateName}:`, error);
    res.status(500).json({ 
      success: false, 
      error: error.message || JSON.stringify(error),
      templateName: req.params.templateName
    });
  }
});

// Get template status
app.get('/api/terraform/:templateName/status', async (req, res) => {
  try {
    const { templateName } = req.params;
    const bucketName = templateBuckets.get(templateName);
    
    let hasState = false;
    let stateFiles = [];
    
    if (bucketName) {
      try {
        const { Contents } = await s3Client.send(new ListObjectsV2Command({ 
          Bucket: bucketName,
          Prefix: `${templateName}/`
        }));
        
        if (Contents && Contents.length > 0) {
          hasState = true;
          stateFiles = Contents.map(obj => obj.Key);
        }
      } catch (error) {
        console.error(`Error checking template status:`, error);
      }
    }
    
    res.status(200).json({
      success: true,
      templateName,
      bucketName,
      hasState,
      stateFiles
    });
  } catch (error) {
    console.error(`Error getting template status:`, error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// List active templates
app.get('/api/templates', async (req, res) => {
  try {
    const templates = [];
    
    for (const [templateName, bucketName] of templateBuckets.entries()) {
      try {
        const { Contents } = await s3Client.send(new ListObjectsV2Command({ 
          Bucket: bucketName,
          Prefix: `${templateName}/`
        }));
        
        templates.push({
          name: templateName,
          bucketName,
          hasState: Contents && Contents.length > 0,
          stateFiles: Contents ? Contents.length : 0
        });
      } catch (error) {
        templates.push({
          name: templateName,
          bucketName,
          hasState: false,
          error: error.message
        });
      }
    }
    
    res.status(200).json({
      success: true,
      templates,
      totalBuckets: createdBuckets.size
    });
  } catch (error) {
    console.error('Error listing templates:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Cleanup all resources
app.post('/api/cleanup', async (req, res) => {
  try {
    const cleanupResult = await cleanupAllBuckets();
    
    // Clear tracking
    templateBuckets.clear();
    createdBuckets.clear();
    
    res.status(200).json({
      success: cleanupResult.success,
      message: cleanupResult.success ? 
        `All resources cleaned up. Deleted ${cleanupResult.deleted} of ${cleanupResult.total} buckets.` : 
        'Error cleaning up some resources',
      details: cleanupResult
    });
  } catch (error) {
    console.error('Error cleaning up resources:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// List all available endpoints
app.get('/', (req, res) => {
  const endpoints = [
    { method: 'GET', path: '/health', description: 'Health check and status' },
    { method: 'POST', path: '/api/terraform/:templateName/init', description: 'Initialize Terraform for template' },
    { method: 'POST', path: '/api/terraform/:templateName/apply', description: 'Apply Terraform configuration' },
    { method: 'POST', path: '/api/terraform/:templateName/destroy', description: 'Destroy Terraform resources' },
    { method: 'GET', path: '/api/terraform/:templateName/status', description: 'Get template status' },
    { method: 'GET', path: '/api/templates', description: 'List all active templates' },
    { method: 'POST', path: '/api/cleanup', description: 'Clean up all resources' }
  ];
  
  res.status(200).json({
    name: 'Terraform API Server',
    version: '2.0.0',
    terraformPath,
    s3Region,
    activeTemplates: Object.fromEntries(templateBuckets),
    createdBuckets: Array.from(createdBuckets),
    endpoints
  });
});

// Start the server
app.listen(port, () => {
  console.log(`Terraform API server v2.0 listening at http://localhost:${port}`);
  console.log(`Using Terraform project path: ${terraformPath}`);
  console.log(`Using AWS region: ${s3Region}`);
  
  // Log available endpoints
  console.log('\nAvailable endpoints:');
  console.log('GET  /health');
  console.log('GET  /');
  console.log('POST /api/terraform/:templateName/init');
  console.log('POST /api/terraform/:templateName/apply');
  console.log('POST /api/terraform/:templateName/destroy');
  console.log('GET  /api/terraform/:templateName/status');
  console.log('GET  /api/templates');
  console.log('POST /api/cleanup');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received: cleaning up and shutting down...');
  cleanupAllBuckets().finally(() => process.exit(0));
});

process.on('SIGINT', () => {
  console.log('SIGINT received: cleaning up and shutting down...');
  cleanupAllBuckets().finally(() => process.exit(0));
});