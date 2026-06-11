const fs = require('fs');
const path = require('path');

const pagesDir = path.join(__dirname, 'src', 'pages');

const tableSkeletonCode = `                [...Array(5)].map((_, i) => (
                  <tr key={i} className="animate-pulse border-b border-white/5">
                    <td colSpan="10" className="px-6 py-5">
                      <div className="flex space-x-4">
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                      </div>
                    </td>
                  </tr>
                ))`;

function processDirectory(directory) {
  const files = fs.readdirSync(directory);
  
  for (const file of files) {
    const fullPath = path.join(directory, file);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      processDirectory(fullPath);
    } else if (file.endsWith('.jsx')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      
      const trLoadingRegex = /\{\s*loading\s*\?\s*\(\s*<tr[^>]*>[\s\S]*?<\/tr>\s*\)\s*:\s*(?!logs\.length === 0)/g;
      
      let newContent = content.replace(trLoadingRegex, (match) => {
        return `{loading ? (\n${tableSkeletonCode}\n              ) : `
      });

      // Specific for AuditTrail because it has nested ternary
      // {loading ? (<tr>...</tr>) : logs.length === 0 ? (<tr>...</tr>) :
      const auditTrailRegex = /\{\s*loading\s*\?\s*\(\s*<tr[^>]*>[\s\S]*?<\/tr>\s*\)\s*:\s*logs\.length === 0/g;
      newContent = newContent.replace(auditTrailRegex, (match) => {
        return `{loading ? (\n${tableSkeletonCode}\n              ) : logs.length === 0`
      });

      if (content !== newContent) {
        fs.writeFileSync(fullPath, newContent, 'utf8');
        console.log(`Added table skeleton to: ${file}`);
      }
    }
  }
}

processDirectory(pagesDir);
console.log('Done!');
