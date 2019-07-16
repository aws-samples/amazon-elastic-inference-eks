FROM python:3.6

WORKDIR /usr/src/app

COPY requirements.txt ./

RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

CMD [ "python", "-u", "./test.py" ]
