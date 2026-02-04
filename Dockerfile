FROM public.ecr.aws/lambda/python:3.12

# 1. System dependencies
RUN dnf install -y \
    gcc gcc-c++ make \
    zip \
    unixODBC unixODBC-devel \
    libstdc++ \
    openssl \
    which \
    tar \
    gzip \
    libtool-ltdl \
    krb5-libs \
    cyrus-sasl-lib \
 && dnf clean all

# 2. Microsoft repo
RUN curl -sSL https://packages.microsoft.com/config/rhel/9/prod.repo \
    -o /etc/yum.repos.d/mssql-release.repo

# 3. Install ODBC Driver 17
RUN ACCEPT_EULA=Y dnf install -y msodbcsql17 \
 && dnf clean all

# 4. Layer structure
RUN mkdir -p /layer/python \
             /layer/odbc/lib \
             /layer/odbc/config

# 5. Install pyodbc
RUN pip install "pyodbc>=5.0.0" -t /layer/python

# 6. Copy native libs to Layer
RUN cp /opt/microsoft/msodbcsql17/lib64/* /layer/odbc/lib/ && \
    cp /usr/lib64/libodbc* /layer/odbc/lib/ && \
    cp /usr/lib64/libltdl* /layer/odbc/lib/ && \
    cp /usr/lib64/libssl* /layer/odbc/lib/ && \
    cp /usr/lib64/libcrypto* /layer/odbc/lib/ && \
    cp /usr/lib64/libkrb5* /layer/odbc/lib/ && \
    cp /usr/lib64/libgssapi_krb5* /layer/odbc/lib/ 

# 6b. Symlink dla drivera żeby pasował do odbcinst.ini
RUN ln -s /layer/odbc/lib/libmsodbcsql-17.10.so.6.1 /layer/odbc/lib/libmsodbcsql-17.so

# 7. odbcinst.ini
RUN printf "[ODBC Drivers]\n\
ODBC Driver 17 for SQL Server=Installed\n\n\
[ODBC Driver 17 for SQL Server]\n\
Description=Microsoft ODBC Driver 17 for SQL Server\n\
Driver=/opt/odbc/lib/libmsodbcsql-17.so\n\
UsageCount=1\n" \
> /layer/odbc/config/odbcinst.ini

# 8. Zip Layer
WORKDIR /layer
RUN zip -r layer.zip .
