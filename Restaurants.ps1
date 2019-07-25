#Give me a list - any list will do. Here's 26 numbers.
$MyList = Get-Content .\Restaurants.txt
 
#Shuffle your array content but keep them in the same array
 
$MyList = $MyList | Sort-Object {Get-Random}
$FinalList = $MyList | Select-Object -First 1
Show-AnyBox -Title 'AnyBox Demo' -Message "$FinalList" -Buttons 'Ok' -ContentAlignment Center