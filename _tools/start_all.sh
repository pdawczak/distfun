(cd _terraform && terraform output -json ec2_instances | jq '.[]' | xargs -t -I % sh -c 'ssh ec2-user@% "./artifact/bin/distfun_simple stop; rm -rf ./artifact; tar -xzf artifact.tar.gz; ./artifact/bin/distfun_simple daemon"')