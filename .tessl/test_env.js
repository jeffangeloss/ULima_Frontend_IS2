const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

const envPath = 'c:/Users/sarit/OneDrive/Documents/IngSoft2/Proyecto_Soft_Ulima/ULima_Backend_IS2/.env';
console.log('Env Path:', envPath);
console.log('File Exists:', fs.existsSync(envPath));

const content = fs.readFileSync(envPath, 'utf8');
console.log('Raw Content (JSON):', JSON.stringify(content));

const parsed = dotenv.parse(content);
console.log('Parsed Env:', parsed);
