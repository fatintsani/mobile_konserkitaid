const fs = require('fs');
const path = require('path');

const pagesDir = path.join(__dirname, 'src', 'pages');

const skeletonCode = `            <div className="animate-pulse">
              <div className="h-10 bg-[#1C1C1F] rounded-t-lg mb-2"></div>
              {[...Array(5)].map((_, i) => (
                <div key={i} className="flex space-x-4 px-6 py-5 border-b border-white/5">
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                </div>
              ))}
            </div>`;

function processDirectory(directory) {
  const files = fs.readdirSync(directory);
  
  for (const file of files) {
    const fullPath = path.join(directory, file);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      processDirectory(fullPath);
    } else if (file.endsWith('.jsx')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      
      // Match {loading ? ( ... ) :
      // We look for {loading ? ( followed by any characters until the first RefreshCcw or RefreshCw, and then until the closing ) :
      const loadingRegex = /\{\s*loading\s*\?\s*\(\s*<div[^>]*>[\s\S]*?<RefreshC(?:c)?w[\s\S]*?<\/div>\s*\)\s*:\s*\(/g;
      
      let newContent = content.replace(loadingRegex, (match) => {
        return `{loading ? (\n${skeletonCode}\n          ) : (`
      });

      // Special case for Dashboard where loading block is a direct return
      // if (loading) { return <div...><RefreshCw/>...</div>; }
      const dashboardLoadingRegex = /if\s*\(\s*loading\s*\)\s*\{\s*return\s*<div[^>]*>[\s\S]*?<RefreshC(?:c)?w[\s\S]*?<\/div>;\s*\}/g;
      newContent = newContent.replace(dashboardLoadingRegex, (match) => {
        return `if (loading) {\n    return (\n${skeletonCode}\n    );\n  }`
      });

      // Special case for Profile which has if (loading) return <div>Loading...</div>
      // Actually Profile uses `if (loading) { return <div ...>Loading...</div> }` ? No, let's check it manually if script misses it.

      if (content !== newContent) {
        fs.writeFileSync(fullPath, newContent, 'utf8');
        console.log(`Added skeleton to: ${file}`);
      }
    }
  }
}

processDirectory(pagesDir);
console.log('Done!');
