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
our @nameFilters = ("Category:"); # Ignore these names if found within [brackets]
our @itemNames;
our @itemIds;
our $postFilterItemNamesLength = 0;

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
  our $filterCount = @nameFilters;
  print "There are currently [$filterCount] filters active...\n";
  # Apply the name filter to the itemNames array.
  
  my @updatedItemNames;
  # Iterate through the item names
foreach my $itemName (@itemNames) {
    my $match = 0;
    # Iterate through the name filters
    foreach my $nameFilter (@nameFilters) {
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
} else {
  #Provide a failure message
  print "Only item links are currently supported.\n";
  #Do not close the window until the user presses a key
  print "Press any key to exit...\n";
  <STDIN>;
}

print "$postFilterItemNamesLength links created...\n";

print "Item names with no item id found:\n";
my $i = 0;
foreach my $item (@itemNames) {
  if ($itemIds[$i] == 0 or $itemIds[$i] eq "0") {
    print color("red"),"Item [$item] not found.\n", color("reset");
  }
  $i++;
}

#Do not close the window until the user presses a key
print "Press any key to exit...\n";
<STDIN>;

