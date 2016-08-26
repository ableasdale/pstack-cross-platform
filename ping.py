#!/usr/bin/env python

import requests

URL_803 = "http://admin:admin@engrlab-129-041.engrlab.marklogic.com:8040/tree2level.xqy?context=undefined&id=http%3A%2F%2Fservice.nsw.gov.au%2Fsnsw%2FBV%2FModel%23DigitalLicence&includeTypes=&excludeTypes=TASK%2COUTCOME%2CCONTEXT&root=http%3A%2F%2Fservice.nsw.gov.au%2Fsnsw%2FBV%2FModel%23DigitalLicence"

URL_8052 = "http://admin:admin@engrlab-129-044.engrlab.marklogic.com:8041/tree2level.xqy?context=undefined&id=http%3A%2F%2Fservice.nsw.gov.au%2Fsnsw%2FBV%2FModel%23DigitalLicence&includeTypes=&excludeTypes=TASK%2COUTCOME%2CCONTEXT&root=http%3A%2F%2Fservice.nsw.gov.au%2Fsnsw%2FBV%2FModel%23DigitalLicence" 

for i in range(1052):
	r = requests.get(URL_8052)
	print (r.status_code)
	print (r.headers)
	print (r.content)
