#!/bin/bash

while getopts ":f:k:N:K:D:B:C:w:" opt; do
  case "$opt" in
    f) certfile="$OPTARG"
       ;;
    k) keyfile="$OPTARG"
       ;;
    N) subject="$OPTARG"
       ;;
    K) principal="$OPTARG"
       ;;
    D) dns="$OPTARG"
       ;;
    B) presavecmd="$OPTARG"
       ;;
    C) postsavecmd="$OPTARG"
       ;;
    w) waitsec="$OPTARG"
       ;;
  esac
done

if [ -n "$waitsec" ] && echo "$waitsec" | grep -q '^[0-9]*[.]*[0-9]\+$'; then
  sleep $waitsec
fi

output="$(ipa-getcert list -f $certfile 2>&1)"
[ $? -ne 0 ] && exit 1
# Is there a ca-error?
if echo "$output" | grep -q '^\s*ca-error:'; then
  echo "$output" | egrep '^\s*status:|^\s*ca-error:|^\s*stuck:' >&2
  exit 1
fi

# Are the expected DNS subjectAltNames the same as whats already in the certrequest?
if echo "$output" | grep -q '\s*dns:' && [ -n "$dns" ]; then
  # take output of ipa-getcert list | grep dns | strip off the 'dns:' part | replace commas with newlines | 
  #                                    sort/dedup the list | replace newlines with a comma | strip off any leading or ending commas
  output_dns="$(echo "$output" | grep '^\s*dns:' | sed -e 's/^\s*dns:\s*//g' | tr -s ',' '\n' | \
                sort | uniq | tr -s '\n' ',' | sed -e 's/,\+$//g;s/^,\+//g')"

  # take contents of dns argument | replace consecutive commas or spaces with a single comma | replace commas with newlines | 
  #                                    sort/dedup the list | replace newlines with a comma | strip off any leading or ending commas
  fixed_dns="$(echo "$dns" | sed -e 's/[, ]\+/,/g' | tr -s ',' '\n' | \
                sort | uniq | tr -s '\n' ',' | sed -e 's/,\+$//g;s/^,\+//g')"

  if [ "$output_dns" != "$fixed_dns" ]; then
    exit 2
  fi

elif [ -n "$dns" ]; then
  exit 2
fi

# Is the expected principal the same as whats already in the certrequest?
if echo "$output" | grep -q '^\s*principal name:' && [ -n "$principal" ]; then

  # take output of ipa-getcert list | grep principal name | strip off the 'principal name:' and @REALM part 
  output_principal="$(echo "$output" | grep '^\s*principal name:' | sed -e 's/^\s*principal name:\s*//g;s/@.*$//g')"
  if [ "$output_principal" != "$principal" ]; then
    exit 3
  fi
elif [ -n "$principal" ]; then
  # Update 2016-02-21: Depending on the CA profile, the principal wont always appear in the output
  #exit 3
  :
fi

# Is the expected subject the same as whats already in the certrequest?
if echo "$output" | grep -q '^\s*subject:' && [ -n "$subject" ]; then

  # take output of ipa-getcert list | grep subject | strip off the 'subject:' and ,O=REALM part
  output_subject="$(echo "$output" | grep '^\s*subject:' | sed -e 's/^\s*subject:\s*//g;s/,O[U]*=.*$//g')"
  if [ "$output_subject" != "$subject" ]; then
    exit 4
  fi
elif [ -n "$subject" ]; then
  exit 4
fi

# Is the expected keyfile the same as whats already in the certrequest?
if echo "$output" | grep -q '^\s*key pair storage:' && [ -n "$keyfile" ]; then

  # take output of ipa-getcert list | grep key pair storage | 
  #                 strip off 'key pair storage: type=*, location=' part, strip off ending single quote and anything after
  output_keyfile="$(echo "$output" | grep '^\s*key pair storage:' | \
                    sed -e 's/^\s*key pair storage:\s*type=\w\+,location='"'"'//g;s/'"'"'.*$//g')"
  if [ "$output_keyfile" != "$keyfile" ]; then
    exit 5
  fi
elif [ -n "$keyfile" ]; then
  exit 5
fi

# Is the expected presavecmd the same as whats already in the certrequest?
if echo "$output" | grep -q '^\s*pre-save command:' && [ -n "$presavecmd" ]; then

  # take output of ipa-getcert list | grep pre-save command | strip off the 'pre-save command:' part
  output_presavecmd="$(echo "$output" | grep '^\s*pre-save command:' | sed -e 's/^\s*pre-save command:\s*//g')"
  if [ "$output_presavecmd" != "$presavecmd" ]; then
    exit 6
  fi
elif [ -n "$presavecmd" ]; then
  exit 6
fi

# Is the expected postsavecmd the same as whats already in the certrequest?
if echo "$output" | grep -q '^\s*post-save command:' && [ -n "$postsavecmd" ]; then

  # take output of ipa-getcert list | grep post-save command | strip off the 'post-save command:' part
  output_postsavecmd="$(echo "$output" | grep '^\s*post-save command:' | sed -e 's/^\s*post-save command:\s*//g')"
  if [ "$output_postsavecmd" != "$postsavecmd" ]; then
    exit 7
  fi
elif [ -n "$postsavecmd" ]; then
  exit 7
fi
