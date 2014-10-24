#replace TABs \t with stuff
sed 's/\t/  /g' input_file

#remove empty lines
sed '/^$/d' myfile >tt

#remove first 3 characters from each line

sed 's/^.\{3\}//g' checkbox > checkboxes

