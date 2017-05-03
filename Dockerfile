From ruby:2.4

# RUN apt-get update && apt-get install locales locales-all
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN groupadd -r udev && useradd -r -g udev udev

WORKDIR /app
COPY app /app
RUN bundle install

EXPOSE 50080
USER udev

CMD ["ruby", "frontEnd.rb"]
