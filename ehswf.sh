#!/bin/bash
readonly LOGIN_PAGE="http://englishharmony.com/secure/login"
readonly SESSION_COOKIE_NAME="amember_nr"

function usage
{
    echo "usage: $0 username password module lesson [destdir]"
    echo "module = 1..4, lesson = 1..30"
    echo "destdir: destination directory, $PWD by default"
}

# check arguments count:
if [ $# -lt 4 ]; then
    usage; exit 1
fi

username="$1"
password="$2"
module=$3
lesson=$4
destdir=${5-$PWD}

# check arguments values:
if (( $module > 4 || $module < 1 || $lesson > 30 || $lesson < 1 )); then
    usage; exit 1
fi
if [[ -z $username || -z $password ]]; then
    usage; exit 1
fi
if [ ! -d $destdir ]; then
  echo "destination directory doesn't exist: $destdir"
fi

# login with the credentials and write cookies into a temp file:
cookiesFile=$(mktemp) || exit 1
curl -s -S -d "amember_login=$username&amember_pass=$password" -c $cookiesFile $LOGIN_PAGE > /dev/null

# check login status
if cat $cookiesFile | grep -q $SESSION_COOKIE_NAME; then
    echo "login succeed"
else
    echo "login failed"; exit 1
fi

# download lesson html page:
lessonHtmlFile=$(mktemp) || exit 1
curl -b $cookiesFile -o $lessonHtmlFile -s -S http://englishharmony.com/ehsystem/M$module/lesson$lesson.html > /dev/null
# extract a name to be given to swf file:
swf_name=$(perl -nle 'print $& if m{English Harmony System De Luxe Edition - \K[^<]+}' $lessonHtmlFile).swf
# extract swf web address:
swf_address=$(perl -nle 'print $& if m{<param name="movie" value="\K[^"]+}' $lessonHtmlFile)
# check swf_name, swf_address:
if [[ -z $swf_name || -z $swf_address ]]; then
    rm -f $cookiesFile;
    echo "something went wrong with extracting swf info from the website";
    echo "check contents of $lessonHtmlFile"; exit 1
else
    # download swf file:
    echo "downloading $destdir/$swf_name";
    curl -o "$destdir/$swf_name" $swf_address;
    echo "downloading done"
fi
# remove tmp files
rm -f $cookiesFile
rm -f $lessonHtmlFile
