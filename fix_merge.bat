@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
git add backend/routes/audit.js
git commit -m "Audit: permite acces la toti utilizatorii autentificati (nu doar admin)"
git push origin main
echo.
git log --oneline -3
echo.
echo Done!
pause
