#!/bin/bash
# Inspired bt Ben Sadeghipour
#@NahamSec


domain=$1

echo "------------------Recon Started--------------------";
echo "------------------with <3 from @interc3pt3r--------";

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

SECONDS=0


mkdir ~/Recon/$domain
cd ~/Recon/$domain



## Finding Sub-Domains
findomain-linux -r --output -t $domain
cat $domain.txt > domains.txt && rm $domain.txt; # now domains.txt is everything


## GAU
cat domains.txt | gau > all_temp_urls.txt
cat all_temp_urls.txt | grep -v -e "[400]" -e "jpg" -e "png" -e "gif" -e "jpeg"  > all_urls.txt && rm all_temp_urls.txt
cat domains.txt | sort -u | httprobe -c 50 -t 3000 >> responsive.txt
cat responsive.txt | sed 's/\http\:\/\///g' |  sed 's/\https\:\/\///g' | sort -u | while read line; do
probeurl=$(cat ~/Recon/$domain/responsive.txt | sort -u | grep -m 1 $line)
echo "$probeurl" >> ~/Recon/$domain/urllist.txt
done
echo "$(cat ~/Recon/$domain/urllist.txt | sort -u)" > ~/Recon/$domain/urllist.txt
echo  "${yellow}Total of $(wc -l ~/Recon/$domain/urllist.txt | awk '{print $1}') live subdomains were found${reset}"
echo "";

## Wayback scanning
echo "Scanning for Wayback Data"
mkdir ~/Recon/$domain/wayback_data
cat urllist.txt | waybackurls >  ~/Recon/$domain/wayback_data/waybackurls.txt
cat waybackurls.txt | sort -u | unfurl --unique keys > paramlist.txt
cat waybackurls.txt | sort -u | grep -P "\w+\.js(\?|$)" | sort -u > ~/Recon/$domain/wayback_data/js.txt
cat waybackurls.txt | sort -u | grep -P "\w+\.php(\?|$) | sort -u " > ~/Recon/$domain/wayback_data/php.txt 
cat waybackurls.txt | sort -u | grep -P "\w+\.aspx(\?|$) | sort -u " > ~/Recon/$domain/wayback_data/aspz.txt
cat waybackurls.txt | sort -u | grep -P "\w+\.jsp(\?|$) | sort -u " > ~/Recon/$domain/wayback_data/jsp.txt
echo ""
echo "Done with Wayback Urls"
echo "";

# ParamSpider
paramspider.py -d $domain --exclude woff,css,js,png,svg,php,jpg > parSpi.txt
echo "";

## Aquatone
echo "Starting aquatone scan..."
auquatoneThreads=5
chromiumPath=/usr/bin/chromium
mkdir ~/Recon/$domain/aqua
cat urllist.txt | aquatone -chrome-path $chromiumPath -out ~/Recon/$domain/aqua -threads $auquatoneThreads -silent


echo " Scanning Done for $domain " | notify
