FROM osgeo/gdal

RUN apt update && \
    apt-get install -y jq

ADD functions.sh /functions.sh

ADD composite/composite /usr/bin/composite
  
RUN chmod +x /usr/bin/composite