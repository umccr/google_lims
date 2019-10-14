## Data sharing
Send out a request for a Keybase account:

> Dear XYTZ, you have recently requested data from UMCCR. The (presigned) URLs we will share with you are ideally only known to you and therefore we will generate them encrypted since anyone with those URLs can download the soon-to-be-shared files. For that we are using KeyBase in our infrastructure setup. Please create an account at https://keybase.io/ and share your user name with me.

> We will send your a file with a list of URLs which you can use to download the data you have requested. Please keep in mind that those URLs will expire in less that 7 days after they have been generated, so please, download the data as soon as you receive that list.

> We ask you to have this prepared in advance to avoid unnecessary delays with this data sharing transaction.

With the Keybase user name in hand:

1. Find files and write to a file list. Example:

`aws s3 ls --recursive s3://umccr-fastq-data-prod/171220_A00130_0036_BH32JNDSXX/171220_A00130_0036_BH32JNDSXX/WTS/171220_A00130_0036_BH32JNDSXX/ | grep 'V-PH' | grep gz | cut -f 4 -d ' ' > files.txt`

I usually do this by filtering the Google-LIMS to just the samples I want to include, then cutting/pasting the FASTQ links as a starting point. You want to end up with `files.txt` containing the files you'd like to distribute.

2. Restore from Glacier, if needed. Default to 14 days, can shorten depending on how responsive the other party is:

```
for FILE in `cat files.txt`; do aws s3api restore-object --bucket umccr-fastq-data-prod --key $FILE --restore-request '{"Days":14,"GlacierJobParameters":{"Tier":"Standard"}}'; done;
```

3. Wait ~48h until the restore process finishes. Can check on the console or command line, see [wiki](https://github.com/umccr/wiki/blob/98a6e3bfedadbf06052a6b14b4ee4cda6b6247f6/computing/cloud/glacier_restore.md) for details. Once restored, use the `presigned_urls` credentials provided by Roman to generate pre-signed URLs:

```
for FILE in `cat files.txt`; do aws s3 presign --profile presigned_urls --expires-in 604800 s3://umccr-fastq-data-prod/$FILE >> presigned.txt; done;
```

4. Ensure the pre-signed URLs point at the right files.

One way to do this is via a basic script:

```
#!/bin/sh

for url in `cat $1`
do
    curl -s "$url" | head -c 10 | file -
done
```

Run with `sh check.sh presigned.txt`.  You can pipe the output into `sort | uniq -c` and confirm the total number of files match the provided file list.

5. Distribute encrypted file of pre-signed URLs.

Encrypt either using the KeyBase application:

`keybase encrypt -i presigned.txt -o presigned.txt.crypt [TheirKeybaseUserID]`

or via https://keybase.io/encrypt, entering the recipients username. 
Copy and paste the encrypted content (with header) into an email.

6. Use `wget` to iterate over generated pre-signed URLs

```
for FILE in `cat presigned.txt`; do wget $FILE; done;
```

File names will include the pre-signed URL string; if we know the other party will use `wget` or `curl` we can generate a shell script that defines the correct output files instead. 
