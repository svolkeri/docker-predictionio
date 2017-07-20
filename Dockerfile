FROM ubuntu
MAINTAINER Stephan Volkeri

ENV SCALA_VERSION 2.10.5
ENV PIO_VERSION 0.11.0-incubating
ENV SPARK_VERSION 1.6.3
ENV ELASTICSEARCH_VERSION 1.7.6
ENV HBASE_VERSION 1.2.5

ENV PIO_HOME /PredictionIO-${PIO_VERSION}
ENV PATH=${PIO_HOME}/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

#RUN useradd -ms /bin/bash predictionio
RUN apt-get update \
    && apt-get install -y --auto-remove --no-install-recommends curl openjdk-8-jdk libgfortran3 python-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /apache-predictionio-${PIO_VERSION}
RUN curl -O http://mirror.nexcess.net/apache/incubator/predictionio/${PIO_VERSION}/apache-predictionio-${PIO_VERSION}.tar.gz \
    && tar -xvzf apache-predictionio-${PIO_VERSION}.tar.gz -C /apache-predictionio-${PIO_VERSION} \
    && rm apache-predictionio-${PIO_VERSION}.tar.gz \
    && cd apache-predictionio-${PIO_VERSION} \
    && ./make-distribution.sh -Dscala.version=${SCALA_VERSION} -Dspark.version=${SPARK_VERSION} -Delasticsearch.version=${ELASTICSEARCH_VERSION}

RUN tar zxvf /apache-predictionio-${PIO_VERSION}/PredictionIO-${PIO_VERSION}.tar.gz -C /
RUN rm -r /apache-predictionio-${PIO_VERSION}
RUN mkdir /template
#RUN chown -R predictionio:predictionio ${PIO_HOME}
#RUN chown -R predictionio:predictionio /template
#USER predictionio

RUN mkdir /${PIO_HOME}/vendors

WORKDIR /${PIO_HOME}/vendors
RUN curl -O http://mirror.netcologne.de/apache.org/spark/spark-1.6.3/spark-1.6.3-bin-hadoop2.6.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop2.6.tgz -C ${PIO_HOME}/vendors \
    && rm spark-${SPARK_VERSION}-bin-hadoop2.6.tgz

RUN curl -O https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && tar -xvzf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz -C ${PIO_HOME}/vendors \
    && rm elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && echo 'cluster.name: predictionio' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml \
    && echo 'network.host: 127.0.0.1' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml

RUN curl -O http://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar -xvzf hbase-${HBASE_VERSION}-bin.tar.gz -C ${PIO_HOME}/vendors \
    && rm hbase-${HBASE_VERSION}-bin.tar.gz

COPY files/pio-env.sh ${PIO_HOME}/conf/pio-env.sh
COPY files/hbase-site.xml ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml

RUN sed -i "s|VAR_PIO_HOME|${PIO_HOME}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml \
    && sed -i "s|VAR_HBASE_VERSION|${HBASE_VERSION}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml

WORKDIR /

ADD files/entrypoint.sh .

RUN chmod +x /entrypoint.sh

VOLUME "/template"

EXPOSE 7070 8000 9300 9200 8080 4040

ENTRYPOINT ["/entrypoint.sh"]

#CMD pio-start-all && sleep 20s && pio status && tail -f /dev/null
#prepare example: Similar Product Engine Template
#(http://predictionio.incubator.apache.org/templates/similarproduct/quickstart/)
#RUN pio template get apache/incubator-predictionio-template-similar-product MySimilarProduct
#RUN cd MySimilarProduct
#RUN pio app new MyApp1
#
#RUN pip install -U setuptools
#RUN pip install predictionio


#prepare example: Demo-Tapster
#RUN apt-get install git ruby build-essential make
#RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
#RUN curl -L https://get.rvm.io | bash -s stable
#RUN touch ~/.bash_profile
#RUN export PATH=$PATH:/usr/local/rvm/bin:/usr/local/rvm/sbin
#RUN source ~/.bash_profile
#RUN rvm install ruby-2.2.2
#RUN ln -s /usr/local/rvm/rubies/ruby-2.2.2/bin/ruby /usr/bin/ruby
#
#RUN gem install bundler
#RUN git clone https://github.com/PredictionIO/Demo-Tapster.git
#RUN cd Demo-Tapster
#RUN bundle install
