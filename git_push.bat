@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo === Git status ===
git status

echo.
echo === Adauga toate modificarile ===
git add -A

echo.
echo === Commit ===
git commit -m "feat: buton Adauga document cu optiuni manuale si scanare in DocumentsScreen"

echo.
echo === Fetch origin ===
git fetch origin

echo.
echo === Rebase pe origin/main (pastram versiunile noastre la conflicte) ===
git rebase origin/main -X ours

echo.
echo === Push origin main ===
git push origin main

echo.
echo === DONE - Sterge acest fisier dupa ce ai terminat ===
pause
