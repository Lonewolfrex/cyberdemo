#!/bin/bash

# Step1: Download and install OWASP ZAP
cd /home/ec2-user/

pkill -f zap-2.14.0.jar || true
wget https://github.com/zaproxy/zaproxy/releases/download/v2.14.0/ZAP_2.14.0_Linux.tar.gz
tar -xzf ZAP_2.14.0_Linux.tar.gz

# Step2: Install Java and Start ZAP in daemon mode
cd ZAP_2.14.0/
sudo yum install java-17 -y

# Start ZAP in daemon mode
java -jar zap-2.14.0.jar -daemon -port 8080 -config api.disablekey=true &
sleep 30  # Wait for ZAP to initialize

# Function to check if ZAP is running
check_zap_running() {
    curl -s "http://127.0.0.1:8080/JSON/core/view/version" > /dev/null
    return $?
}

# Check if ZAP is running, retry up to 3 times if not
for i in {1..3}; do
    if check_zap_running; then
        echo "ZAP started successfully."
        break
    else
        echo "ZAP did not start correctly, retrying... ($i)"
        sleep 10  # Wait before retrying
    fi
done

# Final check after retries
if ! check_zap_running; then
    echo "ZAP failed to start after multiple attempts."
    exit 1
fi

# Step3: Trigger the Spider Scan
scan_response=$(curl -s "http://127.0.0.1:8080/JSON/spider/action/scan/?url=http://127.0.0.1:8000")
scan_id=$(echo $scan_response | jq -r '.scan')

echo "Scan response: $scan_response"
echo "Scan ID: $scan_id"

if [[ "$scan_id" == "null" ]]; then
    echo "Failed to start spidering, response: $scan_response"
    exit 1
fi

echo "Started spidering with scan ID: $scan_id"

# Step4: Wait for the Spider Scan to finish
while true; do
    status=$(curl -s "http://127.0.0.1:8080/JSON/spider/view/status/?scanId=$scan_id" | jq -r '.status')
    
    echo "Spider status: $status"  # Debugging output
    
    if [[ "$status" == "100" ]]; then
        echo "Spidering completed!"
        break
    fi
    
    sleep 5
    
    if [[ "$status" == "" ]]; then 
        echo "No status received, exiting."
        exit 1 
    fi 
    
    if [[ "$status" == "error" ]]; then 
        echo "Error during spider scanning, exiting."
        exit 1 
    fi 
done              

Step5: Start Active Scan after Spidering completes 
active_scan_response=$(curl -s "http://127.0.0.1:8080/JSON/ascan/action/scan/?url=http://127.0.0.1:8000")
active_scan_id=$(echo $active_scan_response | jq -r '.scan')

echo "Active Scan response: $active_scan_response"

if [[ "$active_scan_id" == "null" ]]; then
    echo "Failed to start active scanning, response: $active_scan_response"
    exit 1
fi

echo "Started active scanning with scan ID: $active_scan_id"

# Step6: Wait for the Active Scan to finish
while true; do
    active_status=$(curl -s "http://127.0.0.1:8080/JSON/ascan/view/status/?scanId=$active_scan_id" | jq -r '.status')
    
    echo "Active Scan status: $active_status"  # Debugging output

    if [[ "$active_status" == "100" ]]; then
        echo "Active scanning completed!"
        break
    fi
    
    sleep 5
    
    if [[ "$active_status" == "" ]]; then 
        echo "No status received, exiting."
        exit 1 
    fi 

    if [[ "$active_status" == "error" ]]; then 
        echo "Error during active scanning, exiting."
        exit 1 
    fi 
done              

# Step7: Generate and save the report of the scan
alerts=$(curl -s "http://127.0.0.1:8080/JSON/core/view/alerts/?baseurl=http://127.0.0.1:8000")
echo "$alerts" > /home/ec2-user/ZAP_2.14.0/zap_scan_results.json

if [ -f /home/ec2-user/ZAP_2.14.0/zap_scan_results.json ]; then
    echo "File zap_scan_results.json created successfully."
    
    # Optional debug output of file contents.
    cat /home/ec2-user/ZAP_2.14.0/zap_scan_results.json  
    
    pkill -f manage.py || true   # Kill Django server process (if needed)
    pkill -f zap-2.14.0.jar || true   # Kill ZAP process (if needed)
    
    echo "Django server and ZAP processes terminated."
else
    echo "Failed to create zap_scan_results.json."
    exit 1
fi

