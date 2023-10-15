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

# Subroutines
sub getSpellListUrlAtLevel() {
  my $classID = shift;
  my $level = shift;
  
  if (not defined $classID or not defined $level) {
    return;
  }

  return "$AllaCloneBaseURL/?a=spells&name=&type=$classID&level=$level&opt=1";
}

sub getWebPageData {
  my ($url) = @_;

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

      #Print a debug statement showing the headers
      print "Debug: Headers: ", join(", ", grep { defined && $_ ne "" } @$headers), "\n";

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
        if ($headers && @$headers == @$row) {
          print "Debug: Table($tableIndex), Row($rowIndex): ", join(", ", grep { defined && $_ ne "" } @$row), "\n";
          @row_data{@$headers} = @$row;
          push @table_data, \%row_data;
          print "Debug: Hash pushed: ", join(", ", map { "$_ => $row_data{$_}" } keys %row_data), "\n";
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

# Get the directory path of the current script
my $dir = getcwd();

print "Would you like to convert names into links for Items, NPCs, Spells, Zones? If you want to use a different tool, state Other. (Enter 'Items', 'NPCs', 'Spells', 'Zones' or 'Other'): ";
my $linkType = <>;
chomp $linkType;

our $text;

if (lc($linkType) eq "items") {

  print "Please enter the file name for your .txt document (within this directory): ";
  my $fileName = <>;
  chomp $fileName;

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
      if ($content =~ /item&id=(\d+)/) {
          $itemId = $1;
          print color("green"),"Item id located [$itemId]...\n", color("reset");
          push @itemIds, $itemId;
      } else {
          print color("red"),"Item id not located...\n", color("reset");
          $itemId = 0;
          push @itemIds, 0;
      }
    } else {
      print color("red"),"Response not received...\n", color("reset");
      push @itemIds, 0;
    }
    $currentNameIndex++;
    $itemId = 0;
    print "----------------------------------------\n";
  }

  print "Replacing item names with Alla Clone links...\n";
  my $i = 0;
  foreach my $item (@itemNames) {
    $text =~ s/\[\[$item\]\]/\[https:\/\/alla.clumsysworld.com\/?a=item&id=$itemIds[$i] $item\]/g;
    $i++;
  }


  print "Saving new file...\n";
  my $newFilePath = substr($filePath, 0, rindex($filePath, '.')) . "_converted.txt";
  sysopen(my $newFile, $newFilePath, O_RDWR|O_CREAT|O_EXCL) or die "Could not create file $newFilePath: $!";
  print $newFile $text;
  close $newFile;

  #Provide a success message
  print "File successfully converted and saved to $newFilePath.\n";
} elsif (lc($linkType) eq "spells") {

  print "Please enter the file name for your .txt document (within this directory): ";
  my $fileName = <>;
  chomp $fileName;

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
    $spell =~ s/ /+/g; #Replace spaces with + for URL
    my $response = $ua->get("$AllaCloneBaseURL/?a=spells&name=$spell");
    my $spellId = 0;
    if ($response->is_success) {
      print "Response received...\n";
      my $content = $response->decoded_content;
      if ($content =~ /spell&id=(\d+)/) {
          $spellId = $1;
          print color("green"),"Spell id located [$spellId]...\n", color("reset");
          push @spellIds, $spellId;
      } else {
          print color("red"),"Spell id not located...\n", color("reset");
          $spellId = 0;
          push @spellIds, 0;
      }
    } else {
      print color("red"),"Response not received...\n", color("reset");
      push @spellIds, 0;
    }
    $currentNameIndex++;
    $spellId = 0;
    print "----------------------------------------\n";
  }

  print "Replacing spell names with Alla Clone links...\n";
  my $i = 0;
  foreach my $spellName (@spellNames) {
    $spellName =~ s/\+/ /g; #Replace + with space for clean name
    my $spellID = $spellIds[$i];
    printf "Replacing spell [$spellName]($spellID) with [https:alla.clumsysworld.com/?a=spell&id=$spellID $spellName\]...\n";
    $text =~ s/\{\{($spellName)\}\}/\[https:\/\/alla.clumsysworld.com\/?a=spell&id=$spellID $spellName\]/g;
    $i++;
  }


  print "Saving new file...\n";
  my $newFilePath = substr($filePath, 0, rindex($filePath, '.')) . "_converted.txt";
  sysopen(my $newFile, $newFilePath, O_RDWR|O_CREAT|O_EXCL) or die "Could not create file $newFilePath: $!";
  print $newFile $text;
  close $newFile;

  #Provide a success message
  print "File successfully converted and saved to $newFilePath.\n";


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

  my @spellNames;
  my @spellClass;
  my @spellLevel;
  my @spellMana;
  my @spellSkill;
  my @spellTargetType;
  my @spellID;
  my $spellCount = 0;



  if (lc($listScope) eq "all") {
    
  } elsif (lc($listScope) eq "bard") {
    my @data = getWebPageData($bardSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "beastlord") {
    my @data = getWebPageData($beastlordSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "berserker") {
    my @data = getWebPageData($berserkerSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "cleric") {
    my @data = getWebPageData($clericSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "druid") {
    my @data = getWebPageData($druidSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "enchanter") {
    my @data = getWebPageData($enchanterSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "magician") {
    my @data = getWebPageData($magicianSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "monk") {
    my @data = getWebPageData($monkSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "necromancer") {
    my @data = getWebPageData($necromancerSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "paladin") {
    my @data = getWebPageData($paladinSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "ranger") {
    my @data = getWebPageData($rangerSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "rogue") {
    my @data = getWebPageData($rogueSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "shadow_knight") {
    my @data = getWebPageData($shadowKnightSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "shaman") {
    my @data = getWebPageData($shamanSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "warrior") {
    my @data = getWebPageData($warriorSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } elsif (lc($listScope) eq "wizard") {
    my @data = getWebPageData($wizardSpellListURL);

    @spellNames = ();
    @spellClass = ();
    @spellLevel = ();
    @spellMana = ();
    @spellSkill = ();
    @spellTargetType = ();
    @spellID = ();


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
  } else {
    print "Invalid class name.\n";
    print "Press any key to exit...\n";
    <STDIN>;
  }

  my @output = ("==Spells==",
                "{| class=\"wikitable\"\t",
                "|Spell Name || Level || Mana || Skill || Target Type",
                "|-");
  my $outputRow = "";

  for (my $i = 0; $i < $spellCount; $i++) {
    $outputRow = "|{{$spellNames[$i]}} || $spellLevel[$i] || $spellMana[$i] || $spellSkill[$i] || $spellTargetType[$i]";
    push @output, $outputRow;
    push @output, "|-";
  }

  push @output, "|}";

  my $outputString = join("\n", @output);

  print "Saving new file...\n";
  #Save to a new file in the root directory with a name matching the class name and "_spell_list.txt"
  my $fileName = "$listScope"."_spell_list.txt";
  $filePath = "$dir/$fileName";
  open(my $newFile, '>', $filePath) or die "Could not open file '$filePath' $!";
  print $newFile $outputString;
  close $newFile;
  print "File successfully created and saved to $filePath.\n";

}

