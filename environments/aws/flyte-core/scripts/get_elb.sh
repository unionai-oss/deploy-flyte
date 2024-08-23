#!/bin/bash
while [ -z "${TF_VAR_flyte_elb_hostname}" ]; do
    export TF_VAR_flyte_elb_hostname=$(kubectl get ingress -n flyte -o json | jq -r '.items[0].status.loadBalancer.ingress[0].hostname')
    echo "Still waiting for the load balancer..."
    sleep 10
done
