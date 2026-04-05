# GIPJAZES V Automated Deployment Script

# 1. Initialize local repository
git init
git add .
git commit -m "🚀 Complete deployment: Fixed sidebar + Added Render/Vercel config"

# 2. Setup GitHub Repository
Write-Host "Creating platform on GitHub..." -ForegroundColor Cyan
git branch -M main
# This command will prompt you to create a repo on GitHub if you have 'gh' CLI, 
# otherwise you can paste your remote URL here:
# git remote add origin https://github.com/YOUR_USERNAME/GIPJAZES-V.git
# git push -u origin main

# 3. Deploy to Vercel
Write-Host "Triggering Vercel Deployment..." -ForegroundColor Green
# If you have Vercel CLI:
# npx vercel --prod
