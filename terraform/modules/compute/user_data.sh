#!/bin/bash
# User Data Script for EC2 Instances

yum update -y
yum install -y httpd amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "metrics": {
    "namespace": "${project_name}-${environment}",
    "metrics_collected": {
      "cpu": {
        "measurement": [{"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"}],
        "totalcpu": false
      },
      "disk": {
        "measurement": [{"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}],
        "resources": ["*"]
      },
      "mem": {
        "measurement": [{"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "${project_name}-${environment}-access-logs",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "${project_name}-${environment}-error-logs",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>${project_name} - ${environment}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            text-align: center;
            background: white;
            padding: 50px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 { color: #333; margin-bottom: 20px; }
        .info { color: #666; margin: 10px 0; }
        .badge {
            display: inline-block;
            padding: 5px 15px;
            background: #667eea;
            color: white;
            border-radius: 20px;
            font-size: 14px;
            margin: 10px 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Infrastructure Pipeline</h1>
        <div class="info"><strong>Project:</strong> ${project_name}</div>
        <div class="info"><strong>Environment:</strong> <span class="badge">${environment}</span></div>
        <div class="info"><strong>Instance ID:</strong> <code>$(ec2-metadata --instance-id | cut -d " " -f 2)</code></div>
        <div class="info"><strong>Availability Zone:</strong> <code>$(ec2-metadata --availability-zone | cut -d " " -f 2)</code></div>
        <p style="margin-top: 30px; color: #999;">Deployed via Infrastructure as Code</p>
    </div>
</body>
</html>
EOF

systemctl start httpd
systemctl enable httpd

echo "OK" > /var/www/html/health
