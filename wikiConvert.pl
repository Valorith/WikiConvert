#!/usr/bin/perl
use LWP::Simple;
use strict;
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

# Get the directory path of the current script
my $dir = getcwd();

print "Please enter the file name for your .txt document (within this directory): ";
my $fileName = <>;
chomp $fileName;

# Concatenate the directory path and file name
our $filePath = "$dir/$fileName";

print "File path is: $filePath\n";

print "Would you like to convert names in brackets [] to Alla clone links for Items, NPCs, Spells or Zones? (Enter 'Items', 'NPCs', 'Spells' or 'Zones'): ";
my $linkType = <>;
chomp $linkType;

our $text;

if (lc($linkType) eq "items") {

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


} else {
  #Provide a failure message
  print "Only item & spell links are currently supported.\n";
  #Do not close the window until the user presses a key
  print "Press any key to exit...\n";
  <STDIN>;
}

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

