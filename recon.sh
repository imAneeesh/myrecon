#!/bin/bash
# Inspired bt Ben Sadeghipour
#@NahamSec


red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

SECONDS=0


domain=$1
echo ""
echo "${red}------------------Recon Started--------------------${reset}";
echo "------------------with <3 from @interc3pt3r--------";
echo ""
usage() { echo -e "Usage: bash recon.sh domain.com [-e] [excluded.domain.com,other.domain.com]\nOptions:\n  -e\t-\tspecify excluded subdomains\n " 1>&2; exit 1; }

while getopts ":d:e:r:" o; do
    case "${o}" in
        d)
            domain=${OPTARG}
            ;;

            #### working on subdomain exclusion
        e)
            set -f
	    IFS=","
	    excluded+=($OPTARG)
	    unset IFS
            ;;

		r)
            subreport+=("$OPTARG")
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "${domain}" ] && [[ -z ${subreport[@]} ]]; then
   usage; exit 1;
fi



todate=$(date +"%Y-%m-%d")
path=$(pwd)
foldername=recon-$todate

mkdir ~/Recon/$domain
cd ~/Recon/$domain
mkdir $foldername
cd $foldername



## Finding Sub-Domains
findomain-linux -r --output -t $domain
cat $domain.txt > domains.txt && rm $domain.txt; # now domains.txt is everything

## Checking Subdomain-TakeOver
echo ""
echo "${red}Checking for Sub-domain Takeover....${reset}"
subzy -hide_fails -targets domains.txt > sub_take.txt ;
sed -i '1,7d' sub_take.txt && bash alert.bat sub_take.txt ;
echo "";

## GAU
cat domains.txt | gau > all_temp_urls.txt
cat all_temp_urls.txt | grep -v -e "[400]" -e "jpg" -e "png" -e "gif" -e "jpeg"  > all_urls.txt && rm all_temp_urls.txt
cat domains.txt | sort -u | httprobe -c 50 -t 3000 >> responsive.txt
cat responsive.txt | sed 's/\http\:\/\///g' |  sed 's/\https\:\/\///g' | sort -u | while read line; do
probeurl=$(cat ~/Recon/$domain/$foldername/responsive.txt | sort -u | grep -m 1 $line)
echo "$probeurl" >> ~/Recon/$domain/$foldername/urllist.txt
done
echo "$(cat ~/Recon/$domain/$foldername/urllist.txt | sort -u)" > ~/Recon/$domain/urllist.txt
echo  "${yellow}Total of $(wc -l ~/Recon/$domain/$foldername/urllist.txt | awk '{print $1}') live subdomains were found${reset}"
echo "";

## Wayback scanning
echo "${yellow}Scanning for Wayback Data ${yellow}"
mkdir ~/Recon/$domain/$foldername/wayback_data
cat urllist.txt | waybackurls >  ~/Recon/$domain/$foldername/wayback_data/waybackurls.txt
cat ~/Recon/$domain/$foldername/wayback_data/waybackurls.txt | sort -u | unfurl --unique keys > paramlist.txt
cat ~/Recon/$domain/$foldername/wayback_data/waybackurls.txt | sort -u | grep -P "\w+\.js(\?|$)" | sort -u > ~/Recon/$domain/$foldername/wayback_data/js.txt
cat ~/Recon/$domain/$foldername/wayback_data/waybackurls.txt | sort -u | grep -P "\w+\.php(\?|$) | sort -u " > ~/Recon/$domain/$foldername/wayback_data/php.txt 
cat ~/Recon/$domain/$foldername/wayback_data/waybackurls.txt | sort -u | grep -P "\w+\.aspx(\?|$) | sort -u " > ~/Recon/$domain/$foldername/wayback_data/aspz.txt
cat ~/Recon/$domain/$foldername/wayback_data/waybackurls.txt | sort -u | grep -P "\w+\.jsp(\?|$) | sort -u " > ~/Recon/$domain/$foldername/wayback_data/jsp.txt
echo ""
echo "Done with Wayback Urls"
echo "";

# ParamSpider
paramspider.py -d $domain --exclude woff,css,js,png,svg,php,jpg > parSpi.txt
cat parSpi.txt | grep "http" > paramSpi.txt && rm parSpi.txt

echo "";

## Aquatone
echo "${yellow} Starting aquatone scan...${reset}"
auquatoneThreads=5
chromiumPath=/usr/bin/chromium
mkdir ~/Recon/$domain/$foldername/aquatone
cat urllist.txt | aquatone -chrome-path $chromiumPath -out ~/Recon/$domain/$foldername/aquatone -threads $auquatoneThreads -silent



excludedomains(){
  # from @incredincomp with love <3
  echo "Excluding domains (if you set them with -e)..."
  IFS=$'\n'
  # prints the $excluded array to excluded.txt with newlines 
  printf "%s\n" "${excluded[*]}" > ./$domain/$foldername/excluded.txt
  # this form of grep takes two files, reads the input from the first file, finds in the second file and removes
  grep -vFf ./$domain/$foldername/excluded.txt ./$domain/$foldername/alldomains.txt > ./$domain/$foldername/alldomains2.txt
  mv ./$domain/$foldername/alldomains2.txt ./$domain/$foldername/alldomains.txt
  #rm ./$domain/$foldername/excluded.txt # uncomment to remove excluded.txt, I left for testing purposes
  echo "Subdomains that have been excluded from discovery:"
  printf "%s\n" "${excluded[@]}"
  unset IFS
}



echo " Scanning Done with <3 for $domain " | notify



##############################################################






