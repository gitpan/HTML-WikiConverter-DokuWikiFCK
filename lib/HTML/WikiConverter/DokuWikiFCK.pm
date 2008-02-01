package HTML::WikiConverter::DokuWikiFCK;

#
#
# DokuWikFCK - A WikiCoverter Dialect for interfacing DokuWiki
# and the FCKEditor (http://www.fckeditor.net)
# which seeks to implement the graphic features of FCKEditor
#
# Myron Turner <turnermm02@shaw.ca>
#
# GNU General Public License Version 2 or later (the "GPL")
#    http://www.gnu.org/licenses/gpl.html
#
#

use warnings;
use strict;

use base 'HTML::WikiConverter::DokuWiki';
use HTML::Element;
use  HTML::Entities;

our $VERSION = '0.11';

  my $SPACEBAR_NUDGING = 1;
  my  $color_pattern = qr/
        ([a-zA-z]+)|                                #colorname 
        (\#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}))|        #colorvalue
        (rgb\(([0-9]{1,3}%?,){2}[0-9]{1,3}%?\))     #rgb triplet
        /x;
 
  my $font_pattern = qr//; 
  my %style_patterns = ( 'color' => \$color_pattern, 'font' => \$font_pattern );       

  my $nudge_char = '&#183;';
  my $NL_marker = '~~~'; 
  my $EOL = '=~='; 
  
sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{'strike_out'} = 0;   # this prevents deletions from being paragraphed
  $self->{'list_type'} = "";
  $self->{'list_output'} = 0;   # tells postprocess_output to clean up lists, if 1
  $self->{'in_table'} = 0;
  $self->{'do_nudge'} = $SPACEBAR_NUDGING;
  if(!$self->{'do_nudge'}) {
        $nudge_char = ' ';
  }

#  $self->{'_fh'} = $self->getFH();  
   $self->{'_fh'} = 0;  # turn off debugging  
   return $self;
}


sub getFH {
  return 0;

  local *FH; 
  if(open(FH, ">> /var/tmp/fckw.log")) {
     return *FH;
  }

  return 0;
}

sub rules {
  my $self = shift;
  my $rules = $self->SUPER::rules();
 
  $rules->{ 'span' } = { replace => \&_span_contents };
  $rules->{ 'p' }  = {replace => \&_p_alignment };
  $rules->{ 'img' }  = {replace => \&_image };
  $rules->{ 'a' } =   { replace => \&_link };
  $rules->{ 'blockquote' } = { replace => \&_block };
  $rules->{ 'pre' } =  { start => '<code>', end => '</code>' }; 
  $rules->{ 'var' } =   { start => '//', end => '//' }; 
  $rules->{ 'address' } =  { start => '//', end => '//' }; 
  $rules->{ 'strike' } =  { start => '<del>', end => '</del>' }; 
  $rules->{ 'cite' } =  { start => '//', end => '//' }; 
  $rules->{ 'del' } =   { alias => 'strike'  };
  $rules->{ 'tt' } =    { replace => \&_typewriter }; 
  $rules->{ 'code' } =  { replace => \&_code_types }; 
  $rules->{ 'kbd' } =   { replace => \&_typewriter }; 
  $rules->{ 'samp' } =  { replace => \&_code_types }; 
  $rules->{ 'ins' } =   { alias => 'u' }; 
  $rules->{ 'q' }   =   { start => '"', end => '"' };  
  $rules->{ 'li' }   =  { line_format => 'multi', trim => 'leading', start => \&_li_start,
                         end => $EOL};
  $rules->{ 'ul' } =  { line_format => 'multi', block => 1, line_prefix => '  ',
                            end => "\n<align left></align>\n" },
  $rules->{ 'ol' } = {  alias => 'ul' };
  $rules->{ 'hr' } = { replace => "$NL_marker\n----\n" };
  $rules->{ 'indent' } = { replace => \&_indent  };
  $rules->{ 'header' } = { preserve => 1  };
  $rules->{ 'td' } = { replace => \&_td_start };
  $rules->{ 'th' } = { alias => 'td' };
  $rules->{ 'tr' } = { start => "$NL_marker\n", line_format => 'single' };
  for( 1..5 ) {
    $rules->{"h$_"} = { replace => \&_header };
  }
  
  return $rules;
}


sub _td_start {
  my($self, $node, $rules ) = @_;
    my $text = $self->get_elem_contents($node);

 
    my $prefix =  $self->SUPER::_td_start($node, $rules); 
    my $atts =$self->_get_basic_attributes($node);
    
    $text = $self->fix_td_color($atts,$text);   

    if($atts->{'background'}) {
        $text=~ s/(\s{3,})/$self->_spaces_to_strikeout($1,$atts->{'background'})/ge;
    }
  

   my $suffix = $self->_td_end($node,$rules);

  $text =~ s/\n/ /gm;

   return $prefix . $text . $suffix;
   
}

sub fix_td_color {
   my($self,$atts,$text) = @_;


   my @colors = ();

   if($text =~ /<color.*?<color/ms) {

       while($text =~/<color(.*?)>/gms) {          
             my $color_str = $1;             
             $color_str =~ s/, /,/g;     
             my @elems = split '/', $color_str;        
             push @colors, {fg=>$elems[0],bg=>$elems[1]};  
       }

       my $fg = ""; my $bg = "";
       my $dummy_fg = ""; my $dummy_bg = ""; 
       my $dummy_set = 0; 
       foreach my $color_h(@colors) {
           if($color_h->{'fg'} ne $color_h->{'bg'}) {
               if ($color_h->{'fg'} =~ /_dummy_/ ||  $color_h->{'bg'} =~ /_dummy_/) {
                     if(!$dummy_set) { 
                         $dummy_fg = $color_h->{'fg'}; 
                         $dummy_bg = $color_h->{'bg'};
                     }
                   }
                   else {
                      $fg = $color_h->{'fg'}; 
                      $bg = $color_h->{'bg'};       
                      last; 
                   }
               }
       
           
       }

       if(!$fg) {
           $fg = $dummy_fg ? $dummy_fg : '_dummy_';   
       }
       if(!$bg) {
           $bg = $dummy_bg ? $dummy_bg : '_dummy_';   
       }     
       
       $text=~ s/<color.*?>/ /gms; 
       $text=~ s/<\/color>/ /gms;
       
       return "<color $fg/$bg>$text</color>";

   }

  return $text;
}

#
#  A helper method for _get_type  
#
# This extracts an attribute value from an HTML::Element
#    $attr:  name of attribute being sought
#    $values:  ref to any array of HTML::Elements
# The first instance found is treated as a hit.  Typically there is only
# one element in the array; if there is more than one, it would probably be a syntax error,
# i.e. more than one style element holding the same attribute governing the same text element
sub _extract_values {
  my ($self, $attr, $values) = @_;
  my $HTML_Elements = scalar @$values;

  return $values->[0]->{$attr} if exists $values->[0]->{$attr};

  $HTML_Elements--;
  if($HTML_Elements) {
     return $values->[$HTML_Elements]->{$attr} if exists $values->[$HTML_Elements]->{$attr};
  }
  
 return ""; 
}

#
#  A helper method for _get_type  
#
#   $at: style attribute, colon separated pair:
#            name:value
#   $search_term is the name of attribute being sought
#
sub _extract_style_value {
   my($self, $at, $search_term) = @_;

   my($attribute, $value) = split /:/, $at;

   $attribute =~ s/^\s+//;
   $attribute =~ s/\s+$//;

   $value =~ s/^\s+//;
   $value =~ s/\s+$//;

   return $value if $attribute eq $search_term;
   return 0;
}


#
#  This method extracts the attributes from span elements which apply to a particular
#  text string.  Applicable spans are often nested, so that we have to seaarch both
#  parent and child nodes (spans) to make sure that we have found the attributes that
#  apply to the text.  Also, sometimes css names/values are not separated out from the
#  style attribute; sometimes they are and are treated as separate attributes.  Therefore,
#  we have to check the style attribute for embedded name/value pairs.
#
#
sub _get_type {
   my ($self, $node, $attrs,$type) = @_;

   my $valuepat =  ${$style_patterns{$type}};
   my %ret_values=();  

    #
    #     First check for attributes values in descendent nodes
    #

       #  $node->look_down() returns an array of HTML::Element
    my @values_1 = $node->look_down($attrs->[0], $valuepat);    
    if(@values_1) {
       my $retv =  $self->_extract_values($attrs->[0],\@values_1);
       if($retv) {
          $ret_values{$attrs->[0]} = $retv;
       }
     }
   
  
    my @values_2 = $node->look_down($attrs->[1], $valuepat) if scalar @$attrs == 2;

    if(@values_2) {
       my $retv =  $self->_extract_values($attrs->[1],\@values_2);
       if($retv) {
          $ret_values{$attrs->[1]} = $retv;
       }
     }

    if(!exists $ret_values{$attrs->[1]} || !exists $ret_values{$attrs->[0]}) {        
        my @style_values = $node->look_down('style',$font_pattern);
        if(@style_values) {
                # extract the style attribute from first accessible element of HTML::Element array
                # typically there is only one and the first found is considered a hit
            my $retv =  $self->_extract_values('style',\@style_values);          
                                     
            if(!exists $ret_values{$attrs->[0]}) {
                     # style attributes have to be split from attribute_name:value   
                     # this is done in _extract_style_value()
                my $attr_val =$self->_extract_style_value($retv, $attrs->[0]);
                if($attr_val) { 
                    $ret_values{$attrs->[0]} = $attr_val;   
                }
            }
            if($attrs->[1] && !exists $ret_values{$attrs->[1]}) {
                my $attr_val =$self->_extract_style_value($retv, $attrs->[1]);
                if($attr_val) {
                    $ret_values{$attrs->[1]} = $attr_val;   
                }
           }
          
        }
    }



    #
    #     Then check for attributes values in inherited nodes
    #
    if(!exists $ret_values{$attrs->[0]}) {    
        my @values_1a =   $node->look_up($attrs->[0], $valuepat);
        if(@values_1a) {
           my $retv =  $self->_extract_values($attrs->[0],\@values_1a);
           if($retv) {
              $ret_values{$attrs->[0]} = $retv;
           }
         }
    }
 
    if($attrs->[1] && !exists $ret_values{$attrs->[1]}) {    
        my @values_2a =   $node->look_up($attrs->[1], $valuepat);
        if(@values_2a) {
           my $retv =  $self->_extract_values($attrs->[1],\@values_2a);
           if($retv) {
              $ret_values{$attrs->[1]} = $retv;
           }
         }
    }
 
        if(!exists $ret_values{$attrs->[0]}) {    
            my @values_3 = $node->attr_get_i($attrs->[0]);
            foreach my $val(@values_3) {
                   $ret_values{$attrs->[0]} = $val;  # if there is a hit, take the first one, there 
                   last;                            # shouldn't be more
                }     
            }
    
     if($attrs->[1] && !exists $ret_values{$attrs->[1]}) {
        my @values_4 = $node->attr_get_i($attrs->[1]);
        foreach my $val(@values_4) {

               $ret_values{$attrs->[1]} = $val;
               last;                            # ditto to above
        }
     }


    if(!exists $ret_values{$attrs->[1]} || !exists $ret_values{$attrs->[0]}) {
        my @values_5 = $node->attr_get_i("style");
        foreach my $at(@values_5) {

                                     #style attributes have to be split from attribute string:attribute_name:value   
            if(!exists $ret_values{$attrs->[0]}) {
                if($at =~ /$attrs->[0]/) {
                   my $attr_val =$self->_extract_style_value($at,$attrs->[0]);
                   if($attr_val) {     
                       $ret_values{$attrs->[0]} = $attr_val;   
                       last;          
                   }
                }     
            }

            if($attrs->[1] && !exists $ret_values{$attrs->[1]}) {
                if($at =~ /$attrs->[1]/) {
                   my $attr_val =$self->_extract_style_value($at, $attrs->[1]);
                  if($attr_val) {     
                       $ret_values{$attrs->[1]} = $attr_val;   
                       last;
                  }
                }     
            }
          
        }
    }
 
 
   return %ret_values;
}




#
#   this method processes color and font attributes
#   it calls _get_type() to search parent and child nodes for the applicabe attributes
#
#   this method may be called multiple times for the same text node,
#   so if the string is finished being constructed we just return it back;
#   $node->get_elem_contents() returns the updated string
#
sub _span_contents {
  my($self, $node, $rules ) = @_;

  my $text = $self->get_elem_contents($node);
  my $current_text = "";   # used where more than one span occurs in the markup retrieved as $text
 
  if($text =~ /\s*^<(color|font).*?\/(color|font)/) {
       return $text;
   }

  elsif($text =~ /(.*?)<(color|font).*?\/(color|font)/) {       
          $current_text = $1;
          $text =~ s/^$current_text//;
  }
  
 
  my %color_atts = $self->_get_type($node, ['color','background-color'], 'color');
  if(%color_atts) {  

    my $fg = (exists $color_atts{'color'}) ? ($color_atts{'color'}) : "";
    my $bg = (exists $color_atts{'background-color'}) ? ($color_atts{'background-color'}) : "";

    $fg = 'black' if($fg eq 'white' && !$bg);

    if($fg eq $bg && $text =~ /<indent/) {
          $fg = '_dummy_';
    }
    if($current_text) {          
          $current_text = "<color $fg/$bg>$current_text</color>"; 
    }
      $text = "<color $fg/$bg>$text</color>";

    }

  

  my %font_atts = $self->_get_type($node, ['size', 'face'], 'font');
  if(%font_atts) {  
    my $size = (exists $font_atts{'size'}) ? ($font_atts{'size'}) : "_dummy_";
    my $face = (exists $font_atts{'face'}) ? ($font_atts{'face'}) : "_dummy_"; 
    if($current_text) {
        $text = "<font $size/$face>$current_text</font><font $size/$face>$text</font>";  
    }
   else {
       $text = "<font $size/$face>$text</font>";  
    }
  }


  return $text;
}

#
# Used for basic text formats --typwriter, code, etc
# Extracts text from font tags to prevent duplication
# --causing the duplicate font tags to be treated as part of the text 
sub clean_text {
 my($self, $text) = @_;
    $text =~ s/<.*?>/ /gs;
    $text =~ s/\s+/ /gs;
          
    return $text;
}

sub _typewriter {
   my($self, $node, $rules ) = @_;
   my $text = $self->get_elem_contents($node) || ""; 
    return "" if ! $text;
    $text = $self->clean_text($text);     
    return '<font _dummy_/AmerType Md BT,American Typewriter,courier New>' . $text . '</font>';
}

sub _code_types {
    my($self, $node, $rules ) = @_;
    my $text = $self->get_elem_contents($node) || "";

    return "" if ! $text;
  
    
    my $style = $node->attr('style');  

    $text = $self->clean_text($text);     
    
    return '<font _dummy_/courier New>' . $text . '</font>';

}



sub _li_start {
  my($self, $node, $rules ) = @_;
  my $text = $self->get_elem_contents($node) || "";
  my $type = $self->SUPER::_li_start($node, $rules);
  $self->{'list_output'} = 1;  # signal postprocess_output to clean up lists
  return  "$NL_marker$type";
}

sub _p_alignment {
  my($self, $node, $rules ) = @_;
  my $output = $self->get_elem_contents($node) || "";
 
  if($node->parent) {
    my $tag = $node->parent->tag(); 
    if($tag eq 'td') { 
          return $output . "<br />";
    }
  }


  my $newline = "";
                     # insures that a nudge at start of paragraph
                     # maintains its position at the left-hand margin
                     # instead of being attached to the line preceding it on subsequent saves
  if($self->{'do_nudge'}  &&  $output =~ /^\s{3,}/) {   
       $newline = "<align 1px></align>";
  }
  if($self->{'do_nudge'}) {  
      $output =~ s/(?=<color\s+rgb.*?\/(rgb.*?)>)(.*?)(?=\<)/$self->_spaces_to_strikeout($2,$1)/gmse;
                    # covers insertion after previous processing
                    # a later insertion of spaces myst be preceded by a previous insertion character
                    # which means that a new insertion can't be made immediately after a non-insertion charater
     $output =~ s/(\x{b7}|$nudge_char)([\s\x{a0}]+)/$1 . $self->_space_convert($2)/ge;
  }
  if($self->{'strike_out'}) {
        $self->{'strike_out'} = 0;
        return $output; 
  }

  my $align = $node->{'style'} if exists $node->{'style'};
  
  my $align_tag = "";

  my $aligns_cnt = 0;
  if($align) {   # there have been some styles with multiple attributes, hence this code
      my @styles = split ';', $align if($align);   
      foreach my $style(@styles) { 
          my ($att, $val) = split ':', $style;   
  
          if ($att && $val)
          {
           $att =~ s/^\s//;
           $att =~ s/\s$//;  
            if($att =~ /(text\-align|margin\-left)/) {
               $val =~ s/^\s//;
               $val =~ s/\s$//;  
               $align_tag .= " <align $val>";
               $aligns_cnt++;
            }
          }
      }
   }
   if(!$align_tag) {
      $align_tag = "<align>";
   }
  
  

     $output = "${align_tag}\n${output}\n</align>";
     $aligns_cnt--;     
     if($aligns_cnt) {
       for(0...$aligns_cnt) {
           $output .= " </align> ";
       }
     }
 
                # compensate for lost // in image markup {{http:www.example.com. . .}}                
                # embedded in lib/fetch.exe link
                # when images are fetched from FCK's userfiles directory instead of from
                # DokuWiki's media manager directories

     $output=~s/http\:(?!\/\/)/http:\/\//gsm;
     $output =~ s/\/{3,}/\/\//g; # removes extra newline markers at start and end of images

 return $newline . $output;
}


sub _dwimage_markup {
  my ($self, $src) = @_;
  $src =~ s/\//:/g;   
  if($src !~ /:/) {
      return "{{:$src}}";
  }
   return "{{$src}}";
}

sub _image { 
    my($self, $node, $rules ) = @_;

   my $src = $node->attr('src') || '';

   return "" if(!$src);


  my $w = $node->attr('width') || 0;
  my $h = $node->attr('height') || 0;

  if(!$w) {
       $w = $node->attr('w') || 0;
  }
  if(!$h) {
     $h = $node->attr('h') || 0;
  }

  if( $w and $h ) {
    $src .= "?${w}x${h}";
  } elsif( $w ) {
    $src .= "?${w}";
  }

   # an internal image, fetched from DokuWiki's image manager FCKeditor
   if($src !~ /userfiles\/image/) {
          my @elems = split /=/, $src;
          $src = pop @elems; 
         return $self->_dwimage_markup($src);
   }


   if($src =~ /editor\/images\/smiley\/msn/) {
        if($src =~ /media=(http:.*?\.gif)/) {
              $src = $1;
        }
       else {
            my $HOST = $self->base_uri;
            $src = 'http://' . $HOST . $src if($src !~ /$HOST/);
       }

        return "{{$src}}";
   }
  
   if($src =~ s/^\/userfiles\/image\///) {
         return $self->_dwimage_markup($src);
   }

    #  Fail-Safe mode, in case none of above work
    my $img_url = $self->SUPER::_image($node, $rules);

    $img_url =~ s/%25/%/g;
    $img_url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    $img_url =~ s/%25/%/g;
    $img_url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;


   # prevents piling on of media attributes
   my @elems = split /media/, $img_url;
   if (scalar @elems > 2) {   
       my $last_el = pop @elems;
       my $dw_markup = $last_el;
            # try to convert image to standard DW markup
       if($dw_markup =~ s/^(.*?)userfiles\/image\///) {
         return $self->_dwimage_markup($dw_markup);
       }
       $img_url = $elems[0] . 'media' . $last_el;
   }


    return $img_url;
   
}



sub _indent {
    my($self, $node, $rules ) = @_;     

    my @list = $node->content_list();
    my $color = 'white';

    foreach my $n(@list) {
       if(exists($n->{'color'})) {
           $color = $n->{'color'};
           last;
       }
    }
    my $text = $self->_as_text($node);
    return "<indent style=\"color:$color\">$text</indent>";
}


sub _link {
    my($self, $node, $rules ) = @_;   
    my $url = $node->attr('href') || '';

    if ($url =~ /^\/(doku\.php\?id=)?((((\w)(\w|_)*)*:)*(\w(\w|_)*)*)$/) {
        # preprocess intenal page links
        # any href that looks like 
        #     "/name:space:page" or "/doku.php?id=name:space:pgae"
        # is set to link to 
        #     "name:space:page"
        $node->attr('href', $2);
    } 
    elsif ($url =~ /^mailto:(.*)(\?.*)?/) {
        # dokuwiki doesn't accept mailto links with
        # any options. 
        return "<" . $1 . ">";
    } 
    elsif ($url =~ /^\/lib\/exe\/fetch.php\?/) {
        my $content = $self->get_elem_contents($node);
        if ($content =~ /{{.*}}/) {
            # this is a link around an external image
            # which is not necessary
            return $content;
        }
        if ($url =~ /media=(.*)(&.*)?/) {
            # this is a resource from the dokuwiki file repository
            return "{{" . $1 . "}}" if lc $1 eq lc $content;
            # dokuwiki does not evaluate markup within
            # the description of a file
            return "{{" . $1 . "|" . $self->_as_text($node) . "}}";
        }
    }
    elsif ($url =~ /^\/lib\/exe\/detail.php\?/) {
        # this link is autogenerated by dokuwiki
        # for images from the repository
        # so we can translate it's content and ignore the link
        my $content = $self->get_elem_contents($node);
        return $content;
    }

    my $output=$self->SUPER::_link($node, $rules);

    my $text = $self->get_elem_contents($node) || "";
    my $emphasis = "";
    if($text =~ /([\*\/_\"])\1/) {
        $emphasis = "$1$1";
    }

    if($text =~ /^(<.*?\w>).*?(<\/.*?>)$/) {
        my $start = $1;
        my $end = $2;

        my $start_pat = $start;
        my $end_pat = $end;
        $start_pat =~ s/(\W)/\\$1/g;
        $end_pat =~ s/(\W)/\\$1/g;

        $text =~ /^$start_pat(.*?)$end_pat$/;  

        $text = $1;
        if($text =~ /\W{2}(.*?)\W{2}/) {
            $text= $1;
        }

        $output =~ s/\|$start_pat.*?$end_pat/|$text/;
        $output = "$start${emphasis}${output}${emphasis}$end";  
    }
    elsif($emphasis) {
        my $pat =~ s/(\W)/\\$1/g;
        $output =~ s/$pat//g;
        $output = "${emphasis}${output}${emphasis}";
    }
    return $output;
}

sub _strike {
    my($self, $node, $rules ) = @_;
    my $text = $self->get_elem_contents($node) || "";
   
    $text = $self->_space_convert($text);     
    $self->{'strike_out'} = 1;  

    return "  <indent style='color:white'>$text</indent>  ";
}

sub _block {
  my($self, $node, $rules ) = @_;
  my $text = $self->get_elem_contents($node) || "";

  if($text =~ /<block/) {
       return $text;
   }

  my $bg = "";
  my $fg = "";
  my %color_atts = $self->_get_type($node, ['color','background-color'], 'color');
  if(%color_atts) {  
    $fg = (exists $color_atts{'color'}) ? ($color_atts{'color'}) : "";
    $bg = (exists $color_atts{'background-color'}) ? ($color_atts{'background-color'}) : "";
    $fg = 'black' if($fg eq 'white' && !$bg);
  }
  if(!$bg) {
      if($text =~ /<color.*?\/(.*?)>/) {
               $bg = $1;
      }
  }
   my $block = "<block 80:25>";
   if($bg) {
      $block = "<block 80:25:${bg}>";
   }
     $text =~ s/^\s+//;          # trim  
     $text =~ s/\s+$//;
     $text =~ s/\n{2,}/\n/g;     # multi
  


   return $block . $text . '</block>';

}

  sub _spaces_to_strikeout {
     my($self, $text, $color) = @_;
     my $style="";
     if($color) {
        $style = "  style=\"color: $color\"";  
     }
     return if ! $self->{'do_nudge'};
                 
     $text =~ s/([\s\x{a0}]{2,})/"  <indent${style}>" . $self->_space_convert($1)  . "<\/indent>  "/ge;
     return $text; 
  }

  sub _space_convert {
     my( $self, $spaces ) = @_;
     my $count = $spaces =~ s/[\s\x{a0}]/$nudge_char/g;   

     return $spaces;
  }



   sub  postprocess_output {
           my($self, $outref ) = @_;  

            $$outref =~ s/^\s+//;          # trim  
            $$outref =~ s/\s+$//;
            $$outref =~ s/\n{2,}/\n/g;     # multi
           
                                          # fix image issues
           $$outref=~s/http\:(?!\/\/)/http:\/\//gsm; # replace missing forward slashes
           $$outref=~s/__(\/\/[\[\{])/$1/gsm;        # remove underlining markup
           $$outref=~s/([\}\]]\/\/)__/$1/gsm;        #   ditto


           $$outref =~ s/\^<align 0px><\/align>//g;           # remove aligns at top of file
           $$outref =~ s/<align>[\s\n]*<\/align>[\s\n]*//gsm;      # remove empty aligns
                                                                  


          if($self->{'do_nudge'}) {  
              $$outref =~ s/(?<![${NL_marker}${nudge_char}\x{b7}])([\s\x{a0}]{3,})(?![${EOL}${nudge_char}\x{b7}])/"  <indent style='color:white'>" . $self->_space_convert($1)  . "<\/indent>\n  "/msge;           
              $$outref =~ s/~{3,}/\n<align left><\/align>/;
              $$outref =~ s/\|(.*?)<\/indent>\n(?=.*\|)/\|$1<\/indent>/mgs;
          }
                         # append align left to each newline, except where DokuWiki requires 
                         # a newline at the left-hand margin, immediately before its markup  
                         # these places are marked with the $NL_marker
         $$outref =~ s/(?<!\w\>)(?<!$NL_marker)\n(?!\<\W\w)/\n<align left><\/align> /gms; 

                    # delete nudges of less than 2 characters, which usually result from extra
                    # paragraphs inserted by FCK
          if($self->{'do_nudge'}) {  
               #  $$outref =~ s/<indent.*?>($nudge_char){1,2}<\/indent>//gms;            
         }

                      # remove the newline marker
          $$outref =~ s/$NL_marker/\n/gms;

                      #remove newlines inside td's: must be done after newline markers removed
          $$outref =~ s/\n\s*(?=\|\n)//gms;

          $$outref =~ s/^\s+//gms;   # delete spaces at start of lines

               # delete all 0 width aligns (which DokuWikiFCK inserts at end of file
               # to produce margin-width of 0 and return cursor to new line)
           $$outref =~ s/(<align 0px>[\n\s]*<\/align>[\n\s]*)+//gms;   

               # squash runs of left aligns to one
           $$outref =~ s/([\n\s]*<align left>[\n\s]*<\/align>[\n\s]*){2,}/\n<align left><\/align>\n/gms;
           $$outref =~ s/(<align left>[\n\s]*<\/align>\\\\[\n\s]*){2,}/\n<align left><\/align>\n/gms;
                                 # clean up lists
           if($self->{'list_output'}) {
              $$outref =~ s/([\*\-])(.*?)($EOL[\s\n]*)/$self->_format_list($1,$2, $3)/gmse; 
           }

          $$outref =~ s/(?!\n)<align left>/\n<align left>/gms;

                # remove left align at end of file, if present
           $$outref =~ s/<align left>[\n\s]*<\/align>[\n\s]$//gms;                            
           
           $$outref =~ s/<indent style=\"color:white"><\/indent>//gms;  # remove blank indents                          

                #insert margin 0 at end of file, so that cursor returns to margin
           $$outref .= "\n<align 0px></align>\n" unless $$outref =~ /<align 0px><\/align>\s*$/;

                # add a left aligned paragraph to make it easier to begin adding text
                # otherwise sometimes cursor gets stuck at previous margin indent
                # this works in conjuntion with the margin 0 above
           $$outref .= "\n<align left></align>\n";


         }


# called by postprocess_output()
sub _format_list {
  my($self,$type, $item, $rest_of_sel) = @_;  

    my $text = "${type}${item}${rest_of_sel}";

    my $prefix = "";   # any matter which precedes list
    my $p = 0;
    pos($text) = 0;

      # We search for list item, making sure we don't mistake HR, Dokuwiki's ----, for an ol->li
    while($text =~ /(.*?)(?<!\-\-\-)(?=[\*\-]\s+.*?$EOL)/gms) {
            $prefix .= $1;
            $p = pos($text);
    }
      pos($text) = $p;
      $text =~ /(.*?)$EOL/gms;
      $item = $self->trim($1); 
      if($item eq '-' || $item eq '*') { 
              $item = "";      #remove empty list items,they overlap previous line
      }

      return "$prefix\n  $item";

}


sub trim {
 my($self,$text) = @_;
  $text =~ s/^\s+//;
  $text =~ s/\s+$//;
   return $text;
}


sub log {
   my($self, $where, $data) = @_;
    my $fh = $self->{_fh};

    if( $fh  ) {
        print $fh "$where:  $data\n";
    }
}

our $_dump_cnt = 1;
sub _node_dump {

  my ($self, $node) = @_;
  open DUMP, " > /var/tmp/dump_" . $_dump_cnt;
  $node->dump(*DUMP);
  close DUMP;

  $_dump_cnt++;

}


sub DESTROY {
 my $self=shift;
 my $fh = $self->{_fh};

 if( $fh ) {
    print $fh "\n-----------\n\n";
    close($fh);
 }
}


sub _get_basic_attributes {
    my($self, $node) = @_;

    my $fg = '';
    my $bg = '';
       my %color_atts = $self->_get_type($node, ['color','background-color'], 'color');
       if(%color_atts) {  
        $fg = (exists $color_atts{'color'}) ? ($color_atts{'color'}) : "";
        $bg = (exists $color_atts{'background-color'}) ? ($color_atts{'background-color'}) : "";
      }

 
      my $face = ''; 
      my $size = ''; 
      my %font_atts = $self->_get_type($node, ['size', 'face'], 'font'); 
      if(%font_atts) {
        $face = (exists $font_atts{'face'}) ? ($font_atts{'face'}) : '';  
        $size = (exists $font_atts{'size'}) ? ($font_atts{'size'}) : "";
      }
      return { 'face'=>$face, 'size'=>$size,'color'=>$fg, 'background'=>$bg };
}


# dokuwiki does not allow any syntax within
# headers, so here we clean those
sub _header {
    my($self, $node, $rules ) = @_;

    # remove html nodes from content
    my $text = $self->_as_text($node);

    $node->tag =~ /(\d)/;

    # get pre and postfix for dokuwiki syntax
    # and pre/append those
    my $pre_and_post_fix = "=" x (7 - $1);

            # keep header markup on its own line    
    my $str =  "\n" . "$NL_marker\n$pre_and_post_fix" . $text . "$pre_and_post_fix\n\n<align left></align>";
    return $str;
}


# this helper is used for the header subroutine, in
# order to return the text without any html tags.
# ( we can not use the $node->as_text() methode, as the
#   WikiConverter parsed it into a <~text text="content">
#   tag... )
sub _as_text {
    my($self, $node) = @_;
    my $text =  join '', map { $self->__get_text($_) } $node->content_list;
    return defined $text ? $text : '';
}

# this helper is used for the header subroutine, in
# order to return the text without any html tags.
# ( we can not use the $node->as_text() methode, as the
#   WikiConverter parsed it into a <~text text="content">
#   tag... )
sub __get_text {
    my($self, $node) = @_;
    $node->normalize_content();
    if( $node->tag eq '~text' ) {
        # we return text nodes
        return $node->attr('text');
    } elsif( $node->tag eq '~comment' ) {
        # we keep comments
        return '<!--' . $node->attr('text') . '-->';
    } else {
        # recurse
        my $output = $self->_as_text($node)||'';
        return $output;
    }
}



1;



