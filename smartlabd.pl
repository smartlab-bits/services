#!/usr/bin/perl
use strict;
use warnings;
use threads;
use JSON;

our @words1 = (), our @words2 = ();
our @lightwords = ("light", "tubelight", "see", "bulb", "dark", "darker", "bright", "brighter", "darken", "brighten", "brightness", "darkness", "dim", "lit");
our @fanwords = ("fan", "hot", "hotter", "warm", "warmer", "cool", "cooler", "cold", "heat", "chill", "chilling", "chilled", "burning", "freezing", "increase", "decrease");
our @roomwords = ("room", "kitchen", "yard", "porch", "here");
our @absolutenegatives = ("no", "not", "off", "make");
our @relativenegatives = ("no", "not", "on");
our @questionwords = ("why");
our @conjunctions = ("and", "but");
our $corLight = 0, our $corFan = 0;
our $offwordLight = 0, our $offwordFan = 0;
our $fanSent = 0, our $lightSent = 0;
our $id1 = "default", our $id2 = "default";
our $rno1, our $rno2;
our $pid1, our $pid2;
# okay, the order of elements in this json matters.
# the house is this:
# 3 rooms. R0: 3 ports- 2 lights, 1 fan
# R1: 2 ports- 1 light, 1 fan
# R2: 1 port- 1 light. THAT's IT. DO NOT ALTER.
our $json;
our $decoded;
our @rooms;
our @rooms_aliases;
our @ports_r;

sub objectify_json {
    $decoded = decode_json($json);
    @rooms = @{ $decoded->{'rooms'} };
    foreach my $i ( 0 .. $#rooms ) {
        $rooms_aliases[$i] = $rooms[$i]->{"room_aliases"};
    }
    foreach my $i ( 0 .. $#rooms ) {
        $ports_r[$i] = $rooms[$i]->{"ports"};
    }
}

sub tokenizeString { # breaks the given sentence into words
    my ($s) = @_;
    my $i = 0;
    foreach my $st (@conjunctions) {
        $i = index $s, $st;
        if ($i != -1) {
            @words1 = split(' ', substr($s, 0, $i));
            @words2 = split(' ', substr($s, $i));
            last;
        }
    }
    if ($i == -1 || (scalar(@words2) == 2)) {
        @words1 = split(' ', $s);
        @words2 = split('',"");
    }
}

sub getid() { #gets room name
      if(scalar(@words1)!=0) {
        foreach my $i (0 .. $#words1) {
            foreach my $rword (@roomwords) {
                if(index($words1[$i], $rword) != -1) {
                    if($rword eq "room" && $words1[$i] eq $rword)
                    { $id1 = $words1[$i-1]." ".$words1[$i]; }
                    else
                    { $id1 = $words1[$i]; }
                }
            }
        }
        }
        if(scalar(@words2)!=0) {
            foreach my $i (0 .. $#words2) {
            foreach my $rword (@roomwords) {
                if(index($words2[$i], $rword) != -1) {
                    if($rword eq "room" && $words2[$i] eq $rword)
                    { $id2 = $words2[$i-1]." ".$words2[$i]; }
                    else
                    { $id2 = $words2[$i]; }
                }
            }
        }
    }
    if($id2 ne "default") {
        if($id1 eq "default") {
            $id1 = $id2;
        }
    } else {
        if($id1 ne "default") {
            $id2 = $id1;
        }
    }
    foreach my $i (0 .. $#rooms_aliases) {
        foreach my $j (0 .. $#{$rooms_aliases[$i]}) {
            if(index($id1, $rooms_aliases[$i][$j]) != -1) {
                $id1 = $rooms[$i]->{"room_id"};
                $rno1 = $i;
            }
            if(index($id2, $rooms_aliases[$i][$j]) != -1) {
                $id2 = $rooms[$i]->{"room_id"};
                $rno2 = $i; 
            }
        }
    }
}

sub recognizeLight() { # gives output for light
	my $lightAct = "";
        if (findLightWords()) {
            if ($lightSent == 1) {
                if (countNegatives1() % 2 == 0) {
                    $corLight = 1;
                }
                if ($offwordLight == 0) {
                    if ($corLight == 1) {
                $lightAct=$id1.$pid1." on\n";
                    } else {
                $lightAct=$id1.$pid1." off\n";
                    }
                } else {
                    if ($corLight == 1) {
                        $lightAct=$id1.$pid1." off\n";
                    } else {
            $lightAct=$id1.$pid1." on\n";
            }
                    }
                }
            elsif ($lightSent == 2) {
                if (countNegatives2() % 2 == 0) {
                    $corLight = 1;
                }
                if ($offwordLight == 0) {
                    if ($corLight == 1) {
            $lightAct=$id2.$pid2." on\n";
                    } else {
            $lightAct=$id2.$pid2." off\n";
            }
                    }
                else {
                    if ($corLight == 1) {
            $lightAct=$id2.$pid2." off\n";
                    } else {
            $lightAct=$id2.$pid2." on\n";
                    }
                }
            }
        }
        resetLight();
    return $lightAct;
    }
    
sub recognizeFan() { # gives output for fan
    my $fanAct = "";
        if (findFanWords()) {
            if ($fanSent == 1) {
                if (countNegatives1() % 2 == 0) {
                    $corFan = 1;
                }
                if ($offwordFan == 0) {
                    if ($corFan == 1) {
            $fanAct=$id1.$pid1." on\n";
                    } else {
                        $fanAct=$id1.$pid1." off\n";
                    }
                } else {
                    if ($corFan == 1) {
            $fanAct=$id1.$pid1." off\n";
                    } else {
            $fanAct=$id1.$pid1." on\n";
                    }
                }
            } elsif ($fanSent == 2) {
                if (countNegatives2() % 2 == 0) {
                    $corFan = 1;
                }
                if ($offwordFan == 0) {
                    if ($corFan == 1) {
                        $fanAct=$id2.$pid2." on\n";
                    } else {
                         $fanAct=$id2.$pid2." off\n";
                    }
                } else {
                    if ($corFan == 1) {
                        $fanAct=$id2.$pid2." off\n";
                    } else {
                        $fanAct=$id2.$pid2." on\n";
                    }
                }
            }
        }
        resetFan();
    return $fanAct;
}

    
sub resetLight() { # self-explanatory
        $corLight = 0;
        $offwordLight = 0;
}
    
sub resetFan() { # self-explanatory
        $corFan = 0;
        $offwordFan = 0;
}
    
sub isQuestion1() { # checks if 1st sentence is a question
        foreach (@questionwords) {
            my $s = $_;
            foreach (@words1) {
                my $word = $_;
                if ($s eq $word) {
                    return 1;
                }
            }

        }
        return 0;
    }

sub isQuestion2() { # checks if second sentence is a question
    foreach (@questionwords) {
    my $s = $_;
            foreach (@words2) {
    my $word = $_;
                if ($s eq $word) {
                    return 1;
                }
            }
        }
        return 0;
    }
    
sub countNegatives1() { # counts negative words in sentence 1
        my $count = 0;
        my @negativewords;
        if (isQuestion1()) {
            @negativewords = @relativenegatives;
        } else {
            @negativewords = @absolutenegatives;
        }
        foreach my $s (@negativewords) {


            foreach my $w (@words1) {
                if ($w eq $s) {
                    $count++;
                }
            }


        }
        return $count;
    }

sub countNegatives2() { # counts negative words in sentence 2
        my $count = 0;
        my @negativewords;
        if (isQuestion2()) {
            @negativewords = @relativenegatives;
        } else {
            @negativewords = @absolutenegatives;
        }
        foreach my $s (@negativewords) {



            foreach my $w (@words2) {
                if ($w eq $s) {
                    $count++;
                }
            }

        }
        return $count;
    }
    
sub findLightWords() { # finds if the sentence contains light-related words and changes offwordLight accordingly
        my $flag = 0;
        foreach my $light (@lightwords) {

            foreach my $s (@words1) {
                if ($s eq $light) {
                    $lightSent = 1;
                    $flag = 1;
                    
                    foreach my $i (0 .. $#{$ports_r[$rno1]}) {
            if($ports_r[$rno1][$i]->{"port_device"} eq "L") {
            $pid1 = $ports_r[$rno1][$i]->{"port_id"};
            }
            }

                    if ($words1[0] eq "dim"||$words1[0] eq "darken"|| (!($s eq $words1[0]) && (index($light, "bright") != -1 || $light eq "lit"))) {
                        $offwordLight = 1;
                    }
                    last;
                }
            }

            foreach my $s (@words2) {
                if ($s eq $light) {
                    $lightSent = 2;
                    $flag = 1;
                    
                    foreach my $i (0 .. $#{$ports_r[$rno2]}) {
            if($ports_r[$rno2][$i]->{"port_device"} eq "L") {
            $pid2 = $ports_r[$rno2][$i]->{"port_id"};
            }
            }

                    if ($words2[1] eq "dim"||$words2[1] eq "darken"|| (!($s eq $words2[1]) && (index($light, "bright") != -1 || $light eq "lit"))) {
                        $offwordLight = 1;
                    }
                    last;
                }
            }
        }
        return $flag;
    }
    
sub findFanWords() { # finds if the sentence contains fan-related words and changes offwordFan accordingly
        my $flag = 0;
        foreach my $fan (@fanwords) {

            foreach my $s (@words1) {
                if ($s eq $fan) {
                    $fanSent = 1;
                    $flag = 1;

                    foreach my $i (0 .. $#{$ports_r[$rno1]}) {
            if($ports_r[$rno1][$i]->{"port_device"} eq "F") {
            $pid1 = $ports_r[$rno1][$i]->{"port_id"};
            }
        }

                    if ($words1[0] eq "heat"||$words1[0] eq "increase"|| (!($s eq $words1[0]) && (index($fan, "cool") != -1 || index($fan, "chill") != -1 || $fan eq "cold" || $fan eq "freezing"))) {
                        $offwordFan = 1;
                    }
                    last;
                }
            }

            foreach my $s (@words2) {
                if ($s eq $fan) {
                    $fanSent = 2;
                    $flag = 1;
                    
                    foreach my $i (0 .. $#{$ports_r[$rno2]}) {
            if($ports_r[$rno2][$i]->{"port_device"} eq "F") {
            $pid2 = $ports_r[$rno2][$i]->{"port_id"};
            }
            }

                    if ($words2[1] eq "heat"||$words2[1] eq "increase"|| (!($s eq $words2[1]) && (index($fan, "cool") != -1 || index($fan, "chill") != -1 || $fan eq "cold" || $fan eq "freezing"))) {
                        $offwordFan = 1;
                    }
                    last;
                }
            }
        }



        return $flag;
    }

sub nlp {
tokenizeString($_[0]);
getid();
my $RESULT = "";
$RESULT = $RESULT.recognizeLight();
$RESULT = $RESULT.recognizeFan();
if(!findLightWords() && !findFanWords()) {
    $RESULT = $RESULT."WHAT?\n";
    }
    return $RESULT;
}

my $LANG="en-in";
my $API="http://www.google.com/speech-api/v1/recognize?lang=$LANG";

my $COUNT=0;
my $FLAG=0;

my $NOISE_TIME=0.1;
my $TOLERANCE=5;
my $SILENCE_TIME=2.0;
sub start_listening{ # TODO add gesure mode: say "gesture" to start kinect prog. then say "switch on/off that light". then get light code from dev_coord.
    while(1) {
        if ($FLAG == 2) {
            my $dev_coords = fetch_dev_coords();
            my $gesture_prog;
            my $action="";
            eval {
                local $SIG{ALRM} = sub {die "alarm\n"};
                alarm 30;
                $gesture_prog = `./GestureRecog.o gesture $dev_coords`;
                alarm 0;
            };

            if ($@) {
                die unless $@ eq "alarm\n";
                print "timed out\n";
            }
            else {
                print "didn't time out\n";
            }

            print "script continues...\n";
#             my $gesture_prog = `./GestureRecog.o gesture $dev_coords`;
            my @ret = split("--", $gesture_prog);
            my $gest = $ret[1];
            if($gest == 0) {
                $action = $action."R0P0";
            } else {
                $action = $action."R0P1";
            }
            my $p_in = "./states.txt";            
            my $curr;
            # print "opening\n";
            open( my $p, "<", $p_in ) or die $!;  
            # print "opened\n";
            while(<$p>) {
#           print "calling change state\n";
                if($gest == 0) {
                    if(substr($_, 5, 1) eq "T") {
                        $action = $action." F\n";
                    } else {
                        $action = $action." T\n";
                    }
                }
                else {
                    if(substr($_, 11, 1) eq "T") {
                        $action = $action." F\n";
                    } else {
                        $action = $action." T\n";
                    }
                }
                
            }
            close($p);
            change_state($action);
        $FLAG = 0;
    }
            
        if ($FLAG == 1)
        {
            print "Listening...."."\n";
        }

        my $JSON = `sox -q -r 16k -t alsa hw:1,0 ./out.flac silence 1 0.1 5% 1 2.0 5% trim 0 15 && wget -O - -o /dev/null --post-file ./out.flac --header="Content-Type: audio/x-flac; rate=16000" "$API"`;
    
        my $STATUS = substr $JSON, 10, 1;

        my $UTTERANCE;

        if($STATUS)
        {
            $UTTERANCE = "Could not recognize.";
        }
        else
        {
            my $OFFSET = (index $JSON, "e\":\"") + 4;
            my $LENGTH = (index $JSON, "\",\"c") - $OFFSET;
            $UTTERANCE = substr $JSON, $OFFSET, $LENGTH;
        }

        print "utterance: $UTTERANCE\n";
        if($UTTERANCE eq "google")
        {
            $FLAG=1;
        }
        elsif($UTTERANCE eq "camera")
        {
            $FLAG=2;
        }
        elsif($UTTERANCE eq "stop" || $COUNT == 3) # max 3 meaningless sentences in succession
        {
            $FLAG=0;
            $COUNT = 0;
            print "Speak google to activate\n";            
        }
        elsif($UTTERANCE eq "die"){
            print "Bye\n";
            my $p_in = "./from_gui.txt";
            open(my $p, ">", $p_in ) or die $!;
            print $p "";
            close($p);
            die;
        }
        elsif($UTTERANCE eq "Could not recognize.")
        {
            print "Please repeat your sentence.\n";
        }
        elsif ($FLAG == 1)
        {
        my $ACTION = nlp($UTTERANCE);
        if($ACTION eq "WHAT?\n")
        {
            $COUNT++;
            print $ACTION;
        }
        else
        {
            $COUNT=0;
            my $str = $ACTION;
            my $ifon = "on";
            my $ifoff = "off";

            $ifon = quotemeta $ifon; # escape regex metachars if present
            $ifoff = quotemeta $ifoff; # escape regex metachars if present

            $str =~ s/$ifon/T/g;    # replace on, off with T, F
            $str =~ s/$ifoff/F/g;

            change_state($str);
#             print "state changed\n";
        }
        # system("echo $ACTION > /dev/ttys2");
        }
    }
}

sub change_state {
    my $IN = $_[0];
    print $IN;
    my $file = "./from_perl.txt";
    open( my $fh, '>', $file );
    chomp $IN;
    print $fh $IN;
    close $fh;
    sleep 2;
}

sub calibrate{
    my $calib_prog = "./GestureRecog.o config";
    my $res = `$calib_prog`; #"2!1111 2222 3333!4444 5555 6666";
    my @t_res = split("--", $res);
    my $avail_lights =  $t_res[1];
    #my $avail_lights =  "2!1111 2222 3333!4444 5555 6666";
    #$calib_prog`; # -> "2 (NLIGHTS)!3 2 4 (L1)!1 2 3 (L2)"
    
    if($avail_lights){
        my @light_split = split("!", $avail_lights);

    # NROOMS is 2.
    # $rooms[0] has kinect. it has '2' lights, as told by $calib_prog. yes.

    # TODO generalize for all ports if type 'L' in R0 and then construct JSON

        my $NLIGHTS = $light_split[0];

    # this is bad, yes.
        $decoded->{'rooms'}[0]->{'ports'}[0]->{'dev_coord'} = $light_split[1];
        $decoded->{'rooms'}[0]->{'ports'}[1]->{'dev_coord'} = $light_split[2];

        open(my $fh, '>', '/tmp/sl-calibrated'); # just create the file.
        close $fh;
        $json = encode_json($decoded); # inserted dev_coord into json.
        my $json_file = "./house_model.json";
        open($fh, ">", $json_file) or die $!;
        print $fh $json;
        close $fh;
    }
}

sub pipe_from_gui{
    my $p_in = "./from_gui.txt";
    my $prev = "";
    while(1){
        if (-e $p_in) {
        # print "opening\n";
        open( my $p, "<", $p_in ) or die $!;  
        # print "opened\n";
            while(<$p>) {
#             print "calling change state\n";
                if($_ ne $prev) {
                    change_state($_."\n");
                    $prev = $_;
                }
            }
        close($p);
        }
    }
}

sub fetch_dev_coords{
    # again, only R0P0 and R0P1 are kinect compatible.
    my $light1 = $decoded->{'rooms'}[0]->{'ports'}[0]->{'dev_coord'};
    my $light2 = $decoded->{'rooms'}[0]->{'ports'}[1]->{'dev_coord'};
    my $dev_coords = "$light1 $light2";
    return $dev_coords;
}

sub launch_comm{
    my $comm_proc = `python ./per2gui.py`;
}

sub main{
    my $json_file = "./house_model.json";
    if(-e $json_file) {
        local $/;
        open my $fh, "<", $json_file or die $!;
        $json = <$fh>;
        close $fh;
    }
    else {
        print "JSON model of the house not found. Exiting...\n";
        exit 1;
    }
    objectify_json();
    unless(-e "/tmp/sl-calibrated"){ # create a file upon calibration.
        calibrate();
        print "CALIBRATED\n";
        sleep(2);
    }

    if($ARGV[0] && $ARGV[0] eq "--force-calibrate"){ # forced calibration
        calibrate();
        print "CALIBRATED\n";
        sleep(2);
    }

    my $gui_pipe_thread = threads->create(\&pipe_from_gui);
#     print "gui thread start\n";
    my $speech_thread = threads->create(\&start_listening);
    my $comm_proc_thread = threads->create(\&launch_comm);
#     print "speech thread start\n";
    my $gui_thread_ret = $gui_pipe_thread->join();
    my $speech_thread_ret = $speech_thread->join();
}

main();