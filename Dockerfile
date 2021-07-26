# MapServer from git master
# ~

FROM debian:buster 
LABEL maintainer="Thomas Michel <thomas.michel@idgeo.fr>"

ENV HOME /root
ENV GDAL_VERSION 3.2.1
ENV GEOS_VERSION 3.5.2
ENV PROJ_VERSION 7.2.1
RUN apt-get update && \
	apt-get install -y apache2 \
		bzip2 \
		build-essential \
		cmake \
		curl \
		git \
		libfreetype6-dev \
		libpng-dev \
		libjpeg62-turbo-dev \
		libcurl4-gnutls-dev \
		libxml2-dev \
		libcairo2-dev \
		libgif-dev \
        libpq-dev \
		libtiff5-dev \
		tar \
		unzip \
		vim \
		wget \
		zlib1g-dev

RUN apt-get install -y libapache2-mod-fcgid libfcgi-dev sqlite3 libsqlite3-dev \
		rm -rf /var/lib/apt/lists/*

# Install GEOS
RUN cd /root && \
	wget http://download.osgeo.org/geos/geos-$GEOS_VERSION.tar.bz2 && \
	tar -xjf geos-$GEOS_VERSION.tar.bz2 && \
	cd geos-$GEOS_VERSION && \
	./configure --prefix=/usr && \
	make && \
	make install && \
	make clean && \
	/sbin/ldconfig

# Install Proj7
RUN cd /root && \
	wget http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz && \
	tar -xzf proj-$PROJ_VERSION.tar.gz && \
	cd proj-$PROJ_VERSION/test && \
	wget http://download.osgeo.org/proj/proj-datumgrid-latest.zip && \
	unzip proj-datumgrid-latest.zip && \
	cd .. && \
	./configure --prefix=/usr && \
	make && \
	make install && \
	make clean && \
	/sbin/ldconfig

# Install GDAL
RUN cd /root && \
	wget http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-$GDAL_VERSION.tar.gz  && \
	tar -zxf gdal-$GDAL_VERSION.tar.gz && \
	cd gdal-$GDAL_VERSION && \
	./configure --with-ogr --prefix=/usr && \
	make && \
	make install && \
	make clean && \
    /sbin/ldconfig
RUN echo "/usr/local/lib" >> /etc/ld.so.conf

# Install MapServer
RUN cd /root && git clone https://github.com/mapserver/mapserver.git \ 
    && mkdir /root/mapserver/build \
    && cd /root/mapserver/build \
    && cmake .. -DWITH_THREAD_SAFETY=1 -DWITH_WMS=1 -DWITH_WFS=1 -DWITH_WCS=1 \ 
	-DWITH_CLIENT_WMS=1 -DWITH_CLIENT_WFS=1 -DWITH_SOS=0 -DWITH_KML=1 -DWITH_GEOS=1 -DWITH_GDAL=1 \
	-DWITH_OGR=1 -DWITH_PROJ=1 -DWITH_CAIRO=1 -DWITH_POSTGIS=1 -DWITH_FRIBIDI=0 -DWITH_HARFBUZZ=0 \
	-DWITH_ICONV=1 -DWITH_RSVG=0 -DWITH_MYSQL=0 -DWITH_CURL=1 -DWITH_LIBXML2=1 -DWITH_GIF=1 \ 
	-DWITH_EXEMPI=0 -DWITH_XMLMAPFILE=0 -DWITH_FCGI=1 -DWITH_PROTOBUFC=0\
    && make \ 
    && make install \
    && cp /usr/local/bin/mapserv /usr/lib/cgi-bin/mapserv.fcgi \
    && /sbin/ldconfig

RUN a2enmod rewrite


# Set Apache environment variables (can be changed on docker run with -e)
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www


EXPOSE 80
# Add FCGI configuration
ADD ./apache/default.conf /etc/apache2/conf-enabled/
ADD ./apache/default.conf /etc/apache2/sites-enabled/
ADD ./test.html /var/www/
ADD ./start.sh /start.sh
RUN mkdir /var/maps
RUN chmod 0755 /start.sh
RUN chown www-data:www-data -R /var/www/
CMD ["bash", "start.sh"]