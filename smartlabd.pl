#!/usr/bin/perl
use strict;
use warnings;
use IPC::System::Simple qw(capture);
use JSON;
use POSIX 'mkfifo';

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
our $json = '{
            "norooms": "2",
            "rooms": [
                {
                    "room_id": "R0",
                    "room_aliases": [
                        "my room",
                        "living room",
                        "default",
                        "here"
                    ],
                    "noports": "2",
                    "ports": [
                        {
                            "port_id": "P0",
                            "port_device": "L",
                            "dev_coord" : 0,
                            "port_aliases": [
                                "light",
                                " bulb"
                            ]
                        },
                        {
                            "port_aliases": [
                                "fan",
                                " cool"
                            ],
                            "port_device": "F",
                            "port_id": "P1"
                        }
                    ]
                },
                {
                    "room_id": "R1",
                    "room_aliases": [
                        "kitchen"
                    ],
                    "noports": "2",
                    "ports": [
                        {
                            "port_id": "P0",
                            "port_device": "L",
                            "dev_coord" : 0,
                            "port_aliases": [
                                "light",
                                " bulb"
                            ]
                        },
                        {
                            "port_aliases": [
                                "fan",
                                " cool"
                            ],
                            "port_device": "F",
                            "port_id": "P1"
                        }
                    ]
                }
            ]
        }';
        
our $decoded = decode_json($json);
our @rooms = @{ $decoded->{'rooms'} };
our @rooms_aliases;
foreach my $i ( 0 .. $#rooms ) {
    $rooms_aliases[$i] = $rooms[$i]->{"room_aliases"};
}
our @ports_r;
foreach my $i ( 0 .. $#rooms ) {
    $ports_r[$i] = $rooms[$i]->{"ports"};
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
    # TODO add pipe to gui telling about state change.
    while(1) {
        if ($FLAG == 1)
        {
            print "Listening...."."\n";
        }

        my $JSON = `sox -r 16k -t alsa hw:1,0 ./out.flac silence 1 0.1 5% 1 2.0 5% trim 0 15 && wget -O - -o /dev/null --post-file ./out.flac --header="Content-Type: audio/x-flac; rate=16000" "$API"`;
    
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
        elsif($UTTERANCE eq "terminate" || $COUNT == 3)
        {
            $FLAG=0;
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
            change_state($ACTION);
        }
        # system("echo $ACTION > /dev/ttys2");
        }
    }
}

sub change_state {
    my $IN = $_[0];
    print $IN;
    my $fifo = "/tmp/named.pipe";
    unless ( -p $fifo ) {
      mkfifo( $fifo, 0666 ) or die $!;
    }
    while (1) {
    open( my $fh, '>', $fifo );
    my $t = scalar localtime;
    warn "writing to fifo at $t\n";
    print $fh "written at $t\n";
    close $fh;
    sleep 2;
  }
}

sub calibrate{
    my $calib_prog = "./calibrator.out";
    my $avail_lights = `$calib_prog`; # -> "2 (NLIGHTS) | 3 2 4 (L1) | 1 2 3 (L2)"
    my @light_split = split("|", $avail_lights);

    # TODO generalize for all ports if type 'L' in R0 and then construct JSON
    $decoded->{'rooms'}[0]->{'ports'}[0]->{'dev_coord'} = $light_split[1]; # this is ONLY for the zeroth device
    $json = encode_json($decoded);
    return $avail_lights;
}

use threads;

sub pipe_from_gui{
    my $p_in;
    while(1){
        # TODO listen to p_in for input from gui
        
        # then change state accordingly.
        #  
        change_state("L1 ON");
    }
}

sub main{
    unless(-e "/tmp/sl-calibrated"){
        my $avail_lights = calibrate();
    }    

    my $gesture_prog = "./gesture.out";

    # TODO
    my $speech_thread = threads->create(\&start_listening);
    my $speech_thread_ret = $speech_thread->join();
    
    my $gui_pipe_thread = threads->create(\&pipe_from_gui);
    
}