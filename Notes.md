# Notes

A place for random notes about this project.

AMI for SLES
I opted to have IaC that would allow to simply "pull the latest" image, essentially with no guardrails or guidance.  This ended up with the SLES 15sp7 image, optimized for K8s.  Which seems like it would be fine.  (and, for the most part it is).  

Issues: 
* image is owned by Amazon 
* image is chost (Container Host) 
* image contains docker which is installed and enabled

Workaround:
I added commands to disable Docker if/when Docker is present and conflicts (which, at this time is only for the security install)



