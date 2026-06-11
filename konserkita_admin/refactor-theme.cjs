const fs = require('fs');
const path = require('path');

const pagesDir = path.join(__dirname, 'src', 'pages');

const replacements = [
  { regex: /bg-blue-50/g, replace: 'bg-blue-500/10' },
  { regex: /bg-purple-50/g, replace: 'bg-purple-500/10' },
  { regex: /bg-pink-50/g, replace: 'bg-pink-500/10' },
  { regex: /bg-orange-50/g, replace: 'bg-orange-500/10' },
  { regex: /bg-green-50/g, replace: 'bg-green-500/10' },
  { regex: /bg-emerald-50/g, replace: 'bg-emerald-500/10' },
  { regex: /bg-red-50/g, replace: 'bg-red-500/10' },
  { regex: /bg-yellow-50/g, replace: 'bg-yellow-500/10' },
  
  // Also fix text colors inside badges or inputs
  { regex: /text-gray-900/g, replace: 'text-white' },
];

function processDirectory(directory) {
  const files = fs.readdirSync(directory);
  
  for (const file of files) {
    const fullPath = path.join(directory, file);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      processDirectory(fullPath);
    } else if (file.endsWith('.jsx')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      let originalContent = content;
      
      for (const rule of replacements) {
        content = content.replace(rule.regex, rule.replace);
      }
      
      if (content !== originalContent) {
        fs.writeFileSync(fullPath, content, 'utf8');
        console.log(`Updated colors: ${file}`);
      }
    }
  }
}

processDirectory(pagesDir);
console.log('Done!');
