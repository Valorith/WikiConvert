#!/usr/bin/perl
use LWP::Simple;
use HTML::TableExtract;
#use strict;
use warnings;
use Cwd;
use Fcntl;
use Fcntl qw(O_RDWR O_CREAT O_EXCL);
use Term::ANSIColor;

# Primary global variables
our $AllaCloneBaseURL = "https://alla.clumsysworld.com";
our @itemNameFilters = ("Category:"); # Ignore these names if found within [brackets]
our @spellNameFilters = ("Category:"); # Ignore these names if found within [brackets]
our @itemNames;
our @spellNames;
our @itemIds;
our @spellIds;
our $postFilterItemNamesLength = 0;
our $postFilterSpellNamesLength = 0;
our $maxLevel = 60;
our $filePath = "";
our $headerCount = 0;
our $dir = ""; # Current working directory

# Secondary global variables
our $bardSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=8&level=$maxLevel&opt=3";
our $beastlordSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=15&level=$maxLevel&opt=3";
our $berserkerSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=16&level=$maxLevel&opt=3";
our $clericSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=2&level=$maxLevel&opt=3";
our $druidSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=6&level=$maxLevel&opt=3";
our $enchanterSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=14&level=$maxLevel&opt=3";
our $magicianSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=13&level=$maxLevel&opt=3";
our $monkSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=7&level=$maxLevel&opt=3";
our $necromancerSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=11&level=$maxLevel&opt=3";
our $paladinSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=3&level=$maxLevel&opt=3";
our $rangerSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=4&level=$maxLevel&opt=3";
our $rogueSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=9&level=$maxLevel&opt=3";
our $shadowKnightSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=5&level=$maxLevel&opt=3";
our $shamanSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=10&level=$maxLevel&opt=3";
our $warriorSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=1&level=$maxLevel&opt=3";
our $wizardSpellListURL = "$AllaCloneBaseURL/?a=spells&name=&type=12&level=$maxLevel&opt=3";
our @spellListUrls = ($bardSpellListURL, $beastlordSpellListURL, $berserkerSpellListURL, $clericSpellListURL, 
$druidSpellListURL, $enchanterSpellListURL, $magicianSpellListURL, $monkSpellListURL, $necromancerSpellListURL, 
$paladinSpellListURL, $rangerSpellListURL, $rogueSpellListURL, $shadowKnightSpellListURL, $shamanSpellListURL, 
$warriorSpellListURL, $wizardSpellListURL);
our @classList = ("Bard", "Beastlord", "Berserker", "Cleric", "Druid", "Enchanter", "Magician", "Monk", "Necromancer",
"Paladin", "Ranger", "Rogue", "Shadow Knight", "Shaman", "Warrior", "Wizard");

# Spell List global variables
our @spellClass;
our @spellLevel;
our @spellMana;
our @spellSkill;
our @spellTargetType;
our @spellID;
our $spellCount = 0;



# Subroutines

sub clearSpellListCache() {
  @spellNames = ();
  @spellClass = ();
  @spellLevel = ();
  @spellMana = ();
  @spellSkill = ();
  @spellTargetType = ();
  @spellID = ();
}


sub getSpellListUrlAtLevel {
  my $classID = shift;
  my $level = shift;
  
  if (not defined $classID or not defined $level) {
    return;
  }

  return "$AllaCloneBaseURL/?a=spells&name=&type=$classID&level=$level&opt=1";
}

sub getSpellList {
  my $classIndex = shift;
  my $className = $classList[$classIndex];
  my $classUrl = $spellListUrls[$classIndex];

  clearSpellListCache();
  my @data = getWebPageData($classUrl);
      
  foreach my $table (@data) {
    foreach my $row (@$table) {
        print "----------------------------------------\n";
        if (defined $row->{'Name'}) {
          push @spellNames, $row->{'Name'};
          print "Name: $spellNames[-1]\n";
          
        }
        if (defined $row->{'Class'}) {
          push @spellClass, $row->{'Class'};
          print "Class: $spellClass[-1]\n";
        }
        if (defined $row->{'Level'}) {
          push @spellLevel, $row->{'Level'};
          print "Level: $spellLevel[-1]\n";
        }
        if (defined $row->{'Mana'}) {
          push @spellMana, $row->{'Mana'};
          print "Mana: $spellMana[-1]\n";
        }
        if (defined $row->{'Skill'}) {
          push @spellSkill, $row->{'Skill'};
          print "Skill: $spellSkill[-1]\n";
        }
        if (defined $row->{'Target Type'}) {
          push @spellTargetType, $row->{'Target Type'};
          print "Target Type: $spellTargetType[-1]\n";
        }
        if (defined $row->{'Spell ID'}) {
          push @spellID, $row->{'Spell ID'};
          print "Spell ID: $spellID[-1]\n";
        }
    }
    $spellCount = @spellNames;
  }

  my $headerRow = "| Spell Name || Mana || Skill || Target Type";
  #count the number of occurances of "||" in $headerRow and subtract one to get the number of columns
  $headerCount = () = $headerRow =~ /\|\|/g;
  $headerCount++; #add one to account for the first column
  my @output = ("==Spells==",
                "{| class=\"wikitable\"\t",
                "|-");
  my $outputRow = "";

  my $currentLevel = 0;
  for (my $i = 0; $i < $spellCount; $i++) {
    
    if ($spellLevel[$i] > $currentLevel) {
      $currentLevel = $spellLevel[$i];
      push @output, "! colspan=\"$headerCount\" | '''Level $currentLevel'''";
      push @output, "|-";
      push @output, $headerRow;
      push @output, "|-";
    }
    $outputRow = "|{{$spellNames[$i]}} || $spellMana[$i] || $spellSkill[$i] || $spellTargetType[$i]";
    push @output, $outputRow;
    push @output, "|-";
  }

  push @output, "|}";

  my $outputString = join("\n", @output);

  # $adjustedClassName should reflect the class name in the format used by the wiki. (i.e. shadow_knight)
  my $adjustClassName = lc($className);
  $adjustClassName =~ s/ /_/g;

  print "Saving new file...\n";
  #Save to a new file in the root directory with a name matching the class name and "_spell_list.txt"
  my $fileName = "$adjustClassName"."_spell_list.txt";
  $filePath = "$dir/$fileName";
  open(my $newFile, '>', $filePath) or die "Could not open file '$filePath' $!";
  print $newFile $outputString;
  close $newFile;
  print "File successfully created and saved to $filePath.\n";


}

sub convertItemNames {
  
  print "Please enter the file name for your .txt document (within this directory): ";
  my $fileName = <>;
  chomp $fileName;
  my $text;

  # Concatenate the directory path and file name
  $filePath = "$dir/$fileName";

  print "File path is: $filePath\n";

  if (-e $filePath && -f $filePath) {
    # File exists and is a regular file
    print "Opening file...\n";
    sysopen(our $file, $filePath, 2) or die "Could not open file $filePath: $!";
    $text = do {local $/; <$file>};
    close $file;
    } else {
        # File does not exist or is not a regular file
        die "$filePath does not exist or is not a regular file";
    }

  
  print "Searching for item names...\n";
  @itemNames = $text =~ /\[\[(.*?)\]\]/g;
  
  our $preFilterItemNamesLength = @itemNames;
  print "[$preFilterItemNamesLength] items detected...\n";

  print "Filtering detected names...\n";
  our $filterCount = @itemNameFilters;
  print "There are currently [$filterCount] filters active...\n";
  # Apply the name filter to the itemNames array.
  
  my @updatedItemNames;
  # Iterate through the item names
  foreach my $itemName (@itemNames) {
      my $match = 0;
      # Iterate through the name filters
      foreach my $nameFilter (@itemNameFilters) {
          # Convert both strings to lowercase for case-insensitivity
          our $LCnameFilter = lc($nameFilter);
          our $LCitemName = lc($itemName);
          # Check if the name filter is found within the item name
          if ($LCitemName =~ /$LCnameFilter/) {
              $match = 1;
              last;
          }
      }
      if (!$match){
          push @updatedItemNames, $itemName;
      }
  }
  @itemNames = @updatedItemNames;

  $postFilterItemNamesLength = @itemNames;
  print "[" . ($preFilterItemNamesLength - $postFilterItemNamesLength) . "] items filtered from the item list...\n";

  #Search for each item in turn using the Alla clone URL pattern
  print "Searching for item IDs...\n";

  my $currentNameIndex = 1;


  foreach my $item (@itemNames) {
    my $ua = LWP::UserAgent->new;
    print "[$currentNameIndex/$postFilterItemNamesLength - " . sprintf("%.1f", ($currentNameIndex/$postFilterItemNamesLength) * 100) . "%] Searching Alla Clone for item id for [$item]...\n";
    my $response = $ua->get("$AllaCloneBaseURL/?a=items_search&&a=items&iname=$item&iclass=0&irace=0&islot=0&istat1=&istat1comp=%3E%3D&istat1value=&istat2=&istat2comp=%3E%3D&istat2value=&iresists=&iresistscomp=%3E%3D&iresistsvalue=&iheroics=&iheroicscomp=%3E%3D&iheroicsvalue=&imod=&imodcomp=%3E%3D&imodvalue=&itype=-1&iaugslot=0&ieffect=&iminlevel=0&ireqlevel=0&inodrop=0&iavailability=0&iavaillevel=0&ideity=0&isearch=1");
    my $itemId = 0;
    if ($response->is_success) {
      print "Response received...\n";
      my $content = $response->decoded_content;
      #print "Debug: Content: $content\n";

      while ($content =~ /id='(\d+)'>([^<]+)</g) {
          push @detectedIDs, $1;
          push @detectedNames, $2;
      }

      # Check if the name stored in $item is equal to any of the detected names, if so, store the associated @detectedIDs in $itemId
      my $i = 0;
      my $nameMatched = 0;
      foreach my $detectedName (@detectedNames) {
        #print a debug statement showing the name comparison below
        #print "Debug: Comparing [$detectedName] to [$item]\n";
        if ($detectedName eq $item) {
          $itemId = $detectedIDs[$i];
          print color("green"),"Item id located [$itemId] for item [$item]...\n", color("reset");
          $nameMatched = 1;
          last;
        }
        $i++;
      }
      if (!$nameMatched) {
        print color("red"),"Item id not located for item [$item]...\n", color("reset");
        $itemId = 0;
      }
    } else {
      print color("red"),"Response not received...\n", color("reset");
      push @itemIds, 0;
    }
    push @itemIds, $itemId;
    print "----------------------------------------\n";
    $currentNameIndex++;
  }

  print "Replacing item names with Alla Clone links...\n";
  my $i = 0;
  foreach my $item (@itemNames) {
    my $itemID = $itemIds[$i];
    if ($itemID > 0) {
      $text =~ s/\[\[$item\]\]/\[https:\/\/alla.clumsysworld.com\/?a=item&id=$itemIds[$i] $item\]/g;
    }
    $i++;
  }


  print "Saving new file...\n";
  my $newFilePath = substr($filePath, 0, rindex($filePath, '.')) . "_converted.txt";
  sysopen(my $newFile, $newFilePath, O_RDWR|O_CREAT|O_EXCL) or die "Could not create file $newFilePath: $!";
  print $newFile $text;
  close $newFile;

  #Provide a success message
  print "File successfully converted and saved to $newFilePath.\n";

}

sub getSpellIdByName {
  my $spellName = shift;

  my $ua = LWP::UserAgent->new;
  print "Searching Alla Clone for spell id for [$spellName]...\n";
  my $formattedSpellName = $spellName;
  $formattedSpellName =~ s/\+/ /g; #Replace + with space for clean name
  my $response = $ua->get("$AllaCloneBaseURL/?a=spells&name=$formattedSpellName");
  my $spellId = 0;
  if ($response->is_success) {
    print "Response received...\n";
    my $content = $response->decoded_content;
    my @detectedNames;
    my @detectedIDs;
    while ($content =~ /<a href="\?a=spell&id=(\d+)">([^<]+)<\/a>/g) {
        push @detectedIDs, $1;
        push @detectedNames, $2;
    }
    #print "Debug: Detected names: ", join(", ", @detectedNames), "\n";
    #print "Debug: Detected IDs: ", join(", ", @detectedIDs), "\n";

    # Check if the name stored in $spell is equal to any of the detected names, if so, stored the associated @detectedIDs in $spellId
    my $i = 0;
    my $nameMatched = 0;
    foreach my $detectedName (@detectedNames) {
      #print a debug statement showing the name comparison below
      #print "Debug: Comparing [$detectedName] to [$spell]\n";
      if ($detectedName eq $spellName) {
        $spellId = $detectedIDs[$i];
        print color("green"),"Spell id located [$spellId] for spell [$spellName]...\n", color("reset");
        $nameMatched = 1;
        last;
      }
      $i++;
    }
    if (!$nameMatched) {
      print color("red"),"Spell id not located for spell [$spellName]...\n", color("reset");
      $spellId = 0;
    }
  } else {
    print color("red"),"Response not received...\n", color("reset");
    $spellId = 0;
  }

  return $spellId;

}

sub convertSpellNames {
  my $fileName = shift;   
  my $text;
  
  # Concatenate the directory path and file name
  $filePath = "$dir/$fileName";
    
  if (-e $filePath && -f $filePath) {
  # File exists and is a regular file
  print "Opening file...\n";
  sysopen(our $file, $filePath, 2) or die "Could not open file $filePath: $!";
  $text = do {local $/; <$file>};
  close $file;
  } else {
      # File does not exist or is not a regular file
      die "$filePath does not exist or is not a regular file";
  }

  
  print "Searching for spell names...\n";
  @spellNames = $text =~ /\{\{(.*?)\}\}/g;
  
  our $preFilterSpellNamesLength = @spellNames;
  print "[$preFilterSpellNamesLength] spells detected...\n";

  print "Filtering detected names...\n";
  our $filterCount = @spellNameFilters;
  print "There are currently [$filterCount] spell filters active...\n";
  # Apply the name filter to the spellNames array.
  
  my @updatedSpellNames;
  # Iterate through the spell names
foreach my $spellName (@spellNames) {
    my $match = 0;
    # Iterate through the name filters
    foreach my $nameFilter (@spellNameFilters) {
        # Convert both strings to lowercase for case-insensitivity
        our $LCnameFilter = lc($nameFilter);
        our $LCspellName = lc($spellName);
        # Check if the name filter is found within the spell name
        if ($LCspellName =~ /$LCnameFilter/) {
            $match = 1;
            last;
        }
    }
    if (!$match){
        push @updatedSpellNames, $spellName;
    }
}
@spellNames = @updatedSpellNames;

  $postFilterSpellNamesLength = @spellNames;
  print "[" . ($preFilterSpellNamesLength - $postFilterSpellNamesLength) . "] spells remaining after applying spell filters...\n";

  #Search for each spell in turn using the Alla clone URL pattern
  print "Searching for spell IDs...\n";

  my $currentNameIndex = 1;


foreach my $spell (@spellNames) {
    my $ua = LWP::UserAgent->new;
    print "[$currentNameIndex/$postFilterSpellNamesLength - " . sprintf("%.1f", ($currentNameIndex/$postFilterSpellNamesLength) * 100) . "%] Searching Alla Clone for spell id for [$spell]...\n";
    my $formattedSpellName = $spell;
    $formattedSpellName =~ s/\+/ /g; #Replace + with space for clean name
    my $response = $ua->get("$AllaCloneBaseURL/?a=spells&name=$formattedSpellName");
    my $spellId = 0;
    if ($response->is_success) {
      print "Response received...\n";
      my $content = $response->decoded_content;
      my @detectedNames;
      my @detectedIDs;
      while ($content =~ /<a href="\?a=spell&id=(\d+)">([^<]+)<\/a>/g) {
          push @detectedIDs, $1;
          push @detectedNames, $2;
      }
      #print "Debug: Detected names: ", join(", ", @detectedNames), "\n";
      #print "Debug: Detected IDs: ", join(", ", @detectedIDs), "\n";

      # Check if the name stored in $spell is equal to any of the detected names, if so, stored the associated @detectedIDs in $spellId
      my $i = 0;
      my $nameMatched = 0;
      foreach my $detectedName (@detectedNames) {
        #print a debug statement showing the name comparison below
        #print "Debug: Comparing [$detectedName] to [$spell]\n";
        if ($detectedName eq $spell) {
          $spellId = $detectedIDs[$i];
          print color("green"),"Spell id located [$spellId] for spell [$spell]...\n", color("reset");
          $nameMatched = 1;
          last;
        }
        $i++;
      }
      if (!$nameMatched) {
        print color("red"),"Spell id not located for spell [$spell]...\n", color("reset");
        $spellId = 0;
      }
    } else {
      print color("red"),"Response not received...\n", color("reset");
      $spellId = 0;
    }
    push @spellIds, $spellId;
    print "----------------------------------------\n";
}

  print "Replacing spell names with Alla Clone links...\n";
  my $i = 0;
  foreach my $spellName (@spellNames) {
    my $adjustedSpellName = $spellName;
    $adjustedSpellName =~ s/\+/ /g; #Replace + with space for clean name
    my $spellID = $spellIds[$i];
    if ($spellID > 0) {
      printf "Replacing spell [$adjustedSpellName]($spellID) with [https:alla.clumsysworld.com/?a=spell&id=$spellID $adjustedSpellName\]...\n";
      $text =~ s/\{\{($spellName)\}\}/\[https:\/\/alla.clumsysworld.com\/?a=spell&id=$spellID $adjustedSpellName\]/g;
    }
    $i++;
  }


  print "Saving new file...\n";
  my $newFilePath = substr($filePath, 0, rindex($filePath, '.')) . "_converted.txt";
  sysopen(my $newFile, $newFilePath, O_RDWR|O_CREAT|O_EXCL) or die "Could not create file $newFilePath: $!";
  print $newFile $text;
  close $newFile;

  #Provide a success message
  print "File successfully converted and saved to $newFilePath.\n";
}

sub convertResearchRecipes {
   print "Please enter the file name for your .txt document (within this directory): ";
  my $fileName = <>;
  chomp $fileName;
  my $text;

  # Concatenate the directory path and file name
  $filePath = "$dir/$fileName";

  print "File path is: $filePath\n";

  if (-e $filePath && -f $filePath) {
    # File exists and is a regular file
    print "Opening file...\n";
    sysopen(our $file, $filePath, 2) or die "Could not open file $filePath: $!";
    $text = do {local $/; <$file>};
    close $file;
    } else {
        # File does not exist or is not a regular file
        die "$filePath does not exist or is not a regular file";
    }

  
  print "Searching for item names within Victoria Recipes...\n";

  # Replace "] " with "] [["
  $text =~ s/\] /] \[\[/g;

  # Replace " + " with "]] + [["
  $text =~ s/ \+ /]] + \[\[/g;

  # Replace " = " with "]] = [["
  $text =~ s/ = /]] = \[\[/g;

  # Add "]]" to the end of every line with a "+"
  $text =~ s/(.*\+.*)/$1]]/g;

  #Locate all item names within [[brackets]]
  @itemNames = $text =~ /\[\[(.*?)\]\]/g;
  
  our $preFilterItemNamesLength = @itemNames;
  print "[$preFilterItemNamesLength] items detected...\n";

  print "Filtering detected names...\n";
  our $filterCount = @itemNameFilters;
  print "There are currently [$filterCount] filters active...\n";
  # Apply the name filter to the itemNames array.
  
  my @updatedItemNames;
  # Iterate through the item names
  foreach my $itemName (@itemNames) {
      my $match = 0;
      # Iterate through the name filters
      foreach my $nameFilter (@itemNameFilters) {
          # Convert both strings to lowercase for case-insensitivity
          our $LCnameFilter = lc($nameFilter);
          our $LCitemName = lc($itemName);
          # Check if the name filter is found within the item name
          if ($LCitemName =~ /$LCnameFilter/) {
              $match = 1;
              last;
          }
      }
      if (!$match){
          push @updatedItemNames, $itemName;
      }
  }
  @itemNames = @updatedItemNames;

  $postFilterItemNamesLength = @itemNames;
  print "[" . ($preFilterItemNamesLength - $postFilterItemNamesLength) . "] items filtered from the item list...\n";

  #Search for each item in turn using the Alla clone URL pattern
  print "Searching for item IDs...\n";

  my $currentNameIndex = 1;


  foreach my $item (@itemNames) {
    my $ua = LWP::UserAgent->new;
    print "[$currentNameIndex/$postFilterItemNamesLength - " . sprintf("%.1f", ($currentNameIndex/$postFilterItemNamesLength) * 100) . "%] Searching Alla Clone for item id for [$item]...\n";
    my $response = $ua->get("$AllaCloneBaseURL/?a=items_search&&a=items&iname=$item&iclass=0&irace=0&islot=0&istat1=&istat1comp=%3E%3D&istat1value=&istat2=&istat2comp=%3E%3D&istat2value=&iresists=&iresistscomp=%3E%3D&iresistsvalue=&iheroics=&iheroicscomp=%3E%3D&iheroicsvalue=&imod=&imodcomp=%3E%3D&imodvalue=&itype=-1&iaugslot=0&ieffect=&iminlevel=0&ireqlevel=0&inodrop=0&iavailability=0&iavaillevel=0&ideity=0&isearch=1");
    my $itemId = 0;
    if ($response->is_success) {
      print "Response received...\n";
      my $content = $response->decoded_content;
      #print "Debug: Content: $content\n";

      while ($content =~ /id='(\d+)'>([^<]+)</g) {
          push @detectedIDs, $1;
          push @detectedNames, $2;
      }

      # Check if the name stored in $item is equal to any of the detected names, if so, store the associated @detectedIDs in $itemId
      my $i = 0;
      my $nameMatched = 0;
      foreach my $detectedName (@detectedNames) {
        #print a debug statement showing the name comparison below
        #print "Debug: Comparing [$detectedName] to [$item]\n";
        if ($detectedName eq $item) {
          $itemId = $detectedIDs[$i];
          print color("green"),"Item id located [$itemId] for item [$item]...\n", color("reset");
          $nameMatched = 1;
          last;
        }
        $i++;
      }
      if (!$nameMatched) {
        print color("red"),"Item id not located for item [$item]...\n", color("reset");
        $itemId = 0;
      }
    } else {
      print color("red"),"Response not received...\n", color("reset");
      push @itemIds, 0;
    }
    push @itemIds, $itemId;
    print "----------------------------------------\n";
    $currentNameIndex++;
  }

  print "Generate text rows for a new text document formatted for the wiki...\n";
  my @rows;
  push @rows, "==Crafted Spells==";
  push @rows, "{| class=\"wikitable\"";
  push @rows, "|-";
  push @rows, "| Scribestone || Energy Focus || Power Component || Required Spell or Tome || Product  || Cost";
  push @rows, "|-";
  my $recipeIndex = 0;
  my $itemIndex = 0;
  my $itemCount = @itemNames;
  my $recipeCount = $itemCount / 5;
  
  #iterate through from 0 to $rowCount - 1
  for ($recipeIndex = 0; $recipeIndex < $recipeCount; $recipeIndex++) {
    my $row = "|";
    #iterate through from 0 to 3
    for (my $i = 0; $i < 5; $i++) {
      my $itemIndex = ($recipeIndex * 5) + $i;
      my $itemName = $itemNames[$itemIndex];
      my $itemId = $itemIds[$itemIndex];
      if ($itemId and $itemId >= 1) {
        if ($i == 4) {
          #remove "Spell: " from the beginning of the spell name
          my $spellName = $itemName;
          $spellName =~ s/Spell: //g;
          my $spellID = getSpellIdByName($spellName);
          $row .= "[https:alla.clumsysworld.com/?a=spell&id=$spellID $spellName] || "
        } else {
          print "Debug: Item Index: $itemIndex, Item Name: $itemName, Item ID: $itemId\n";
          $row .= "[https://alla.clumsysworld.com/?a=item&id=$itemId $itemName] || ";
        }
      } else {
        $row .= "$itemName || ";
      }
      $itemIndex++;
    }
    print "Debug: Row: $row\n";
    $row =~ s/https:alla/https:\/\/alla/g;
    push @rows, $row;
    push @rows, "|-";
  }
  
  push @rows, "|}";

  my $outputString = join("\n", @rows);
  $text = $outputString;

  print "Saving new file...\n";
  my $newFilePath = substr($filePath, 0, rindex($filePath, '.')) . "_converted.txt";
  sysopen(my $newFile, $newFilePath, O_RDWR|O_CREAT|O_EXCL) or die "Could not create file $newFilePath: $!";
  print $newFile $text;
  close $newFile;

  #Provide a success message
  print "File successfully converted and saved to $newFilePath.\n";
}

sub getWebPageData {
  my $url = shift;

  my $ua = LWP::UserAgent->new();
  my $response = $ua->get($url);

  if ($response->is_success) {
    my $content = $response->decoded_content;
    my $te = HTML::TableExtract->new();
    $te->parse($content);

    my @data;

    my $tableIndex = 0;
    foreach my $ts ($te->table_states) {
      $tableIndex++;
      next if ($tableIndex != 3);

      my @table_data;

      # Assuming headers are in the second row of the table
      my $headers = $ts->rows->[1];

      # Remove the "Effect(s)" header completely and shift other headers left
      @$headers = grep { $_ ne "Effect(s)" } grep { defined } @$headers;

    if (grep { $_ eq "Class" } @$headers) {
      my $classIndex = grep { $headers->[$_] eq "Class" } 0..$#$headers;
      splice @$headers, $classIndex, 1, "Class", "Level";
    }
      #Update the header count variable
      $headerCount = @$headers;

      #Print a debug statement showing the headers
      #print "Debug: Headers: ", join(", ", grep { defined && $_ ne "" } @$headers), "\n";

      my $rowIndex = 0;
      foreach my $row (@{$ts->rows}[2..$#{$ts->rows}]) {

        foreach my $value (@$row) {
          $value =~ s/Shadown Knight/SK/g if defined $value;
        }

        s/^\s+|\s+$//g for grep {defined} @$row;

        # Ignore rows where the first value is "Name" (header row)
        next if defined $row->[0] && $row->[0] eq "Name";

        # Remove any undefined, empty string, or empty row values, or values with only a single space in them
        @$row = grep { defined && $_ ne "" && $_ ne " " } @$row;
        next if (@$row == 0);

        # Remove empty values from the beginning of the row
        shift @$row while (@$row && (!defined $row->[0] || $row->[0] eq ""));
        

         # Split the second row value into two values
        if (defined $row->[1]) {
          my ($class, $level) = split / /, $row->[1], 2;
          $row->[1] = $class;
          splice @$row, 2, 0, $level if defined $level;
        }

        # Storing data as hash references
        my %row_data;
        $rowIndex++;
        #print a debug statement showing the header and row count comparison
        my $tempHeaderCount = @$headers;
        my $tempRowCount = @$row;
        print "Debug: Header Count: $tempHeaderCount, Row Count: ", $tempRowCount, "\n";
        if ($headers && @$headers == @$row) {
          #print "Debug: Table($tableIndex), Row($rowIndex): ", join(", ", grep { defined && $_ ne "" } @$row), "\n";
          @row_data{@$headers} = @$row;
          push @table_data, \%row_data;
          #print "Debug: Hash pushed: ", join(", ", map { "$_ => $row_data{$_}" } keys %row_data), "\n";
        } else {
          #warn "Headers and row data are not the same length! Skipping row.\n";
          next;
        }
      }

      push @data, \@table_data;
    }

    return @data;
  } else {
    die "Failed to fetch the URL: $url\n";
  }
}

# Get the current working directory
$dir = getcwd();

print "Would you like to convert names into links for Items, NPCs, Spells, Research, Zones? If you want to use a different tool, state Other. (Enter 'Items', 'NPCs', 'Spells', 'Zones', 'Research' or 'Other'): ";
my $linkType = <>;
chomp $linkType;

if (lc($linkType) eq "items") {

  convertItemNames($fileName);
  
} elsif (lc($linkType) eq "spells") {

  print "Please enter the file name for your .txt document (within this directory): ";
  my $fileName = <>;
  chomp $fileName;

  convertSpellNames($fileName);


} elsif ((lc($linkType) eq "research")) {

  convertResearchRecipes($fileName);

} elsif (!(lc($linkType) eq "other")) {
  #Provide a failure message
  print "Only item & spell links are currently supported.\n";
  #Do not close the window until the user presses a key
  print "Press any key to exit...\n";
  <STDIN>;
} 

if (!(lc($linkType) eq "other")) {
  print "$postFilterItemNamesLength item links created...\n";
  print "$postFilterSpellNamesLength spell links created...\n";

  print "Item names with no item id found:\n";
  my $i = 0;
  foreach my $item (@itemNames) {
    if ($itemIds[$i] == 0 or $itemIds[$i] eq "0") {
      print color("red"),"Item [$item] not found.\n", color("reset");
    }
    $i++;
  }

  print "Spell names with no spell id found:\n";
  $i = 0;
  foreach my $spell (@spellNames) {
    if ($spellIds[$i] == 0 or $spellIds[$i] eq "0") {
      print color("red"),"Spell [$spell] not found.\n", color("reset");
    }
    $i++;
  }

  #Do not close the window until the user presses a key
  print "Press any key to exit...\n";
  <STDIN>;
}



if (lc($linkType) eq "other") { # Other tools menu
  print "What other tool would you like to use? (spellList): ";
  $linkType = <>;
  chomp $linkType;
} 

if (lc($linkType) eq "spelllist") { #Determine scope of conversion: All Classes or Single Class
  print "Do you want to generate a spell list for All classes (all) or a specific class (class_name: i.e. shadow_knight)?: ";
  my $listScope = <>;
  chomp $listScope;



  if (lc($listScope) eq "all") {

    #print a warning in red that asks the player to confirm that they want to generate spell lists for all classes
    print color("red"),"WARNING: This will generate spell lists for all classes. This may take a long time to complete (aprox 20 mins).\n", color("reset");
    print color("red"),"Are you sure you want to continue? (y/n): ", color("reset");
    my $confirm = <>;
    chomp $confirm;
    if (lc($confirm) eq "n") {
      print "Exiting...\n";
      print "Press any key to exit...\n";
      <STDIN>;
      exit;
    }
    
    # Step 1: Clear spell list cache
    print "Step 1: Clearing spell list cache...\n";
    clearSpellListCache();

    # Step 2: Get spell list for each class
    print "Step 2: Pulling spell lists for each class...\n";
    my $classIndex = 0; #Starts with index 0 for bard
    foreach my $classUrl (@spellListUrls) { # For each value in the array, do something
      my $class = $classList[$classIndex];
      print color("green"),"Pulling spell list for: $class\n", color("reset");
      #Add error handling so that if an error occurs, it skips to the next class
      eval { getSpellList($classIndex); };
      if ($@) {
        print color("red"),"Error pulling spell list for ($class): $@\n", color("reset");
        print color("red"),"Skipping to next class...\n", color("reset");
        next;
      }
      $classIndex++;
    }
    
    # Step 3: Convert all spell names to links
    print "Step 3: Converting spell names in spell list files to spell links...\n";
    $classIndex = 0; #Starts with index 0 for bard
    foreach my $className (@classList) { # For each value in the array, do something
      print "Converting spell names in $className spell list...\n";
      #Modify the $className variable to match the file name format. (i.e. shadow_knight)
      $className =~ s/ /_/g;
      $className = lc($className);
      
      print "Debug: Class name: $className\n";
      #include error handling so that if an error occurs, it skips to the next class name
      eval { convertSpellNames("$className"); };
      if ($@) {
        print color("red"),"Error: $@\n", color("reset");
        print color("red"),"Skipping to next class...\n", color("reset");
        next;
      }
      $classIndex++;
    }

  } elsif (lc($listScope) eq "bard") {
    getSpellList(0); #bard
  } elsif (lc($listScope) eq "beastlord") {
    getSpellList(1); #beastlord
  } elsif (lc($listScope) eq "berserker") {
    getSpellList(2); #berserker
  } elsif (lc($listScope) eq "cleric") {
    getSpellList(3); #cleric
  } elsif (lc($listScope) eq "druid") {
    getSpellList(4); #druid
  } elsif (lc($listScope) eq "enchanter") {
    getSpellList(5); #enchanter
  } elsif (lc($listScope) eq "magician") {
    getSpellList(6); #magician
  } elsif (lc($listScope) eq "monk") {
    getSpellList(7); #monk
  } elsif (lc($listScope) eq "necromancer") {
    getSpellList(8); #necromancer
  } elsif (lc($listScope) eq "paladin") {
    getSpellList(9); #paladin
  } elsif (lc($listScope) eq "ranger") {
    getSpellList(10); #ranger
  } elsif (lc($listScope) eq "rogue") {
    getSpellList(11); #rogue
  } elsif (lc($listScope) eq "shadow_knight") {
    getSpellList(12); #shadow_knight
  } elsif (lc($listScope) eq "shaman") {
    getSpellList(13); #shaman
  } elsif (lc($listScope) eq "warrior") {
    getSpellList(14); #warrior
  } elsif (lc($listScope) eq "wizard") {
    getSpellList(15); #wizard
  } else {
    print "Invalid class name.\n";
    print "Press any key to exit...\n";
    <STDIN>;
  }

  

}

