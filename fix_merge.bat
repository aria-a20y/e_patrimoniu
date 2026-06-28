@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
git add .gitignore
git add fix_merge.bat
git add -f lib/core/services/audit_service.dart
git commit -m "Audit: gitignore protejeaza set_audit_3.js, restaureaza try/catch in audit_service.dart"
git push origin main
echo.
git log --oneline -3
echo.
echo Done!
pause
