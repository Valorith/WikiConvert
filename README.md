# WikiConvert

This tool allows you to convert wiki links enclosed in [[double brackets]] (items), {{double curly braces}} (spells), etc into EveryQuest Alla Clone links.

# Item Links
The tool will scan the input .txt file and look up the item ID (from the Alla clone). That item id is then used to inject Alla Clone links in place of the item names
that are in [brackets]. 

The new, modified wiki data is then exported to `<original_file_name>_converted.txt` so you can easily copy/paste it into your wiki editor.


# How To Use

- Ensure you have Perl installed on your machine: https://strawberryperl.com/
- Place the `WikiConvert.pl` script in a folder of your choice.
- Open the above perl script in a text editor and change the `$AllaCloneBaseURL` value to match the base url for your alla clone of choice.
- Adjust the `@itemNameFilters` or `@spellNameFilters` values as desired to filter out any text within [brackets] or {{curlyBraces}} that you do not want converted. Values should all be within the parenthasis, surounded by double quotes and seperated by commas. i.e. `@itemNameFilters = ("Category:", "Filter2", "Filter3");`
- Save your updated script.
- Copy your Wiki markup text from your wiki of choice. Ensure that any item names that you want converted into Alla Clone item links are surrounded by `[[double brackets]]` and any spell names that you want converted into Alla Clone spell links are surrounded by `{{double curly braces}}`.
- Paste the text into a .txt file (within the same directory as the perl script) with a name of your choice. Save the File.
- Open your terminal application of choice (i.e. Command Prompt, Power Shell, etc) and navigate to the folder that the script is in.
- Type `perl wikiConvert.pl`.
- Select (by typing in) your target conversion type. i.e. `items, npc, zones, other`. *** NOTE: CURRENTLY ONLY ITEMS AND SPELLS ARE SUPPORTED.***
- If 'other' is selected, you can choose to use the `spelllist` tool to generate a full spell list converted into markdown format.
- Provide the name of the txt file you created above i.e. `items.txt`
- Hit enter and the tool should start reporting its progress.
- Once complete, the tool will export an output .txt file with the following name: `<origional_input_file_name>_converted.txt`, where `<origioal_input_file_name>` 
is the name of the original .txt file that you loaded into the tool.
- You can now copy/paste the text from the exported output file into your wiki editor. 


![image](https://user-images.githubusercontent.com/76063792/213879566-01cefc9e-84de-4b2c-a261-44e0473cddee.png)

![image](https://user-images.githubusercontent.com/76063792/213879597-9298577b-9073-4484-9b40-a96bd7fc858e.png)

![image](https://user-images.githubusercontent.com/76063792/213879779-c304dd54-045f-4673-9590-04672a404a11.png)

