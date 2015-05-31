# [@bulbatrivia](https://twitter.com/bulbatrivia)

A bot that tweets random trivia from [Bulbapedia](http://bulbapedia.bulbagarden.net).

## Running the bot

Clone the repository and install dependencies:

```bash
git clone https://github.com/alyssais/bulbatrivia
cd bulbatrivia
bundle
```

Configure the bot using the following environment variables:

```bash
TWITTER_USERNAME
TWITTER_CONSUMER_KEY
TWITTER_CONSUMER_SECRET
TWITTER_ACCESS_TOKEN
TWITTER_ACCESS_TOKEN_SECRET
MAINTAINER_SCREEN_NAME
```

Run the bot:

```bash
ebooks start
```

For debugging, you can also get a console.
An instance of the bot will be assigned to the `Bot` variable.

```bash
bin/console
```

## Contributing

1. [Fork it](https://github.com/alyssais/bulbatrivia/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
