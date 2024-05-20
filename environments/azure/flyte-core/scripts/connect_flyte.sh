
#!/bin/bash
resource_group=${1}
cluster_name=${2}
ip_dns_label=${3}

while [ -z "${lb_ip}" ]; do
    export lb_ip=$(kubectl get services ingress-nginx-controller -o wide -n ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "Still looking for the load balancer..."
    sleep 10
done

cluster_resource_group=$(az aks show -n $cluster_name -g $resource_group --query "nodeResourceGroup" -otsv)
ip_id=$(az network public-ip list -g $cluster_resource_group --query "[?ipAddress=='$lb_ip']" | jq '.[0].id' | tr -d '"')

az network public-ip update --ids $ip_id --dns-name $ip_dns_label