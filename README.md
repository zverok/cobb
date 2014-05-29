# Cobb

**Cobb** is "yet another"™ web scraper library, extracted from a real project.

It's named after [Jayne Cobb](http://firefly.wikia.com/wiki/Jayne_Cobb), 
an infamous Serenity "public relation guy" from 
[Firefly](http://en.wikipedia.org/wiki/Firefly_(TV_series)) series.

Some ideas (though, not the code) was taken from 
[sinew](https://github.com/gurgeous/sinew).

## What the funny names?

You see, when we work with web scrapers domain, we'll never come with
very meaningful names, it always be like `Parser.parse`, 
`Evaluator.evaluate` or something like this.

So, I've decided to use names which are, though not domain specific,
at least fun and consistent. So, in my gem, **Cobb** use his **guns**
to **fire**, and makes lot of **victims**. 

And there comes **Vera**.

Deal with it. Maybe I'll change my mind in future versions.

## 1. Just Gun aka "OK, let's start with something"

The simplest usage of Cobb (also look at samples/01_simple.rb):

```ruby
class AmazonBook < Cobb::Gun
  def mechanizm
    result(
      title: html.at!('h1#title #productTitle').text,
      author: html.at!('#byline .author a.contributorNameID').text,
      price: html.at!('#MediaMatrix .swatchElement.selected .a-color-price').text_
    )
  end
end

victim = AmazonBook.fire 'http://www.amazon.com/Cats-Cradle-Novel-Kurt-Vonnegut/dp/038533348X/'

pp victim.result 
# => {"title"=>"Cat's Cradle: A Novel", "author"=>"Kurt Vonnegut", "price"=>"$8.75"}
```

What we see here?

1. how to define gun: just inherit from `Cobb::Gun` and define `mechanizm` 
  method, and everything would work
2. what you get inside `mechanizm`:
  - `html` is `Nokogiri::HTML` of the page 
    (with some `Nokogiri::More`, see below)
  - `result` is method to merge some values to result
3. how to use gun: just do `{Gun}.fire({url})`
4. what you obtain from gun: victim, obviously, and its `result` 
  - it's what you `result`ed in gun. It's a "mash", descended from
  `Hashie::Mash`, so you can `result['title']` or `result.title` now.

What you can't see, yet it's still here: **requests caching**. It's just 
so-called "greedy" caching: once performed, request to some URL is never
repeated again. You can control it just by removing `tmp/cache`, 
and (in future) by settings and commands. But for now it seems good enough:
you just develop some "gun" (parser), and run it as many times as you like,
and results are just got from disk.

It's pretty obivous, yet useful (on my thought), but it's just a start.

## 2. Array of results

But what if we have several data items on page? 
Oh, that's easy (also look at samples/02_array.rb):

```ruby
class AmazonAuthorBooks < Cobb::Gun
  def mechanizm
    author = html.at!('#EntityName').text
    html.css('#mainResults .result').each do |row|
      result_row do
        result(
          title: row.at!('h3.title a').text,
          link: row.at!('h3.title a').href,
          author: author
        )
      end
    end
  end
end

# or:
class AmazonAuthorBooks < Cobb::Gun
  def mechanizm
    author = html.at!('#EntityName').text
    html.css('#mainResults .result').each do |row|
      result_row(
        title: row.at!('h3.title a').text,
        link: row.at!('h3.title a').href,
        author: author
      )
    end
  end
end

victim = AmazonAuthorBooks.fire 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
pp victim.results
# => [{"title"=>"Slaughterhouse-Five",
#      "link"=>"http://www.amazon.com/Slaughterhouse-Five-Kurt-Vonnegut/dp/0440180295",
#      "author"=>"Kurt Vonnegut"},
#     {"title"=>"If This Isn't Nice, What Is?: Advice to the Young-The Graduation Speeches",
#      "link"=>"http://www.amazon.com/This-Isnt-Nice-What-Graduation/dp/1609805917",
#      "author"=>"Kurt Vonnegut"},
#     ... and so on ...
```

As simple as that. You call `result_row{some code}` or even 
`result_row(some_hash)` and you have `victim.results`. One item - 
`victim.result`, many items - `victim.results`. Not too smart, not too
dumb, obvious enough.

## 3. Next targets. Interesting things goes from here!

On my experience, typical real-world site scraping is like "scrape list 
of items from this page, than follow links and scrape their description", 
and so on. With Cobb, you do it totally like this 
(also look at samples/03_next.rb): 

```ruby
module Amazon
  class AuthorBooks < Cobb::Gun
    def mechanizm
      html.css('#mainResults .result').each do |row|
        next_to Book, row.at!('h3.title a').href
      end
    end
  end

  class Book < Cobb::Gun
    def mechanizm
      result(
        title: html.at!('h1#title #productTitle').text,
        author: html.at!('#byline .author a.contributorNameID').text,
        price: html.at!('#MediaMatrix .swatchElement.selected .a-color-price').text_
      )
    end
  end
end

victim = Amazon::AuthorBooks.fire 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
pp victim.next_targets
# => [#<Cobb::Target: Amazon::Book.fire(http://www.amazon.com/Slaughterhouse-Five-Kurt-Vonnegut/dp/0440180295)>,
#     #<Cobb::Target: Amazon::Book.fire(http://www.amazon.com/This-Isnt-Nice-What-Graduation/dp/1609805917)>,
#     ... several of them ...
#     #<Cobb::Target: Amazon::Book.fire(http://www.amazon.com/Suckers-Portfolio-Collection-Previously-Unpublished/dp/1611099587)>]

victim2 = victim.next_targets.first.fire_at!
pp victim2.result
# => {"title"=>"Slaughterhouse-Five", "author"=>"Kurt Vonnegut", "price"=>"$4.83"}
```

Highlights:

1. `next_to({Gun}, {url})` - tells victim the next target and what gun
  to fire at it
2. so, the victim has method `next_targets`, which return instances of
  `Cobb::Target` class, knowing what gun, and what URL to fire, and
  having method `Target#fire_at!` to fire with specified gun
  (cynical enough, no? now you're in love with my namings?..)

Becames cooler, nah? It's just a beginning.

## 4. Context

When you fire at something, you can provide a context, and your gun has
access to it:

```ruby
module Amazon
  class Book < Cobb::Gun
    def mechanizm
      result(
        title: html.at!('h1#title #productTitle').text,
        author: html.at!('#byline .author a.contributorNameID').text,
        price: html.at!('#MediaMatrix .swatchElement.selected .a-color-price').text_,
        author_bio: context.author_bio
      )
    end
  end
end

victim = Amazon::Book.fire 'http://www.amazon.com/Cats-Cradle-Novel-Kurt-Vonnegut/dp/038533348X/', 
  author_bio: 'Sample author bio.'
pp victim.data 
# => {"title"=>"Cat's Cradle: A Novel",
#     "author"=>"Kurt Vonnegut",
#     "price"=>"$8.75",
#     "author_bio"=>"Sample author bio."}
```

It don't looks too cool, until you mix it with `next_to`:

```ruby
module Amazon
  class AuthorBooks < Cobb::Gun
    def mechanizm
      bio = html.at!('#artistCentralBio_officialFullBioContent').text
      html.css('#mainResults .result').each do |row|
        next_to Book, row.at!('h3.title a').href, 
          author_bio: bio # here goes the context!
      end
    end
  end
end

victim = Amazon::AuthorBooks.fire(url)
pp victim.next_targets.first
# => #<Cobb::Target: Amazon::Book.fire(http://www.amazon.com/Slaughterhouse-Five-Kurt-Vonnegut/dp/0440180295) 
#      with #<Cobb::Mash 
#              author_bio="Kurt Vonnegut was born in Indianapolis in 1922. He studied at the universities of Chicago and Tennessee and later began to write short stories for magazines. His first novel, Player Piano, was published in 1951 and since then he has written many novels, among them: The Sirens of Titan (1959), Mother Night (1961), Cat's Cradle (1963), God Bless You Mr Rosewater (1964), Welcome to the Monkey House; a collection of short stories (1968), Breakfast of Champions (1973), Slapstick, or Lonesome No More (1976), Jailbird (1979), Deadeye Dick (1982), Galapagos (1985), Bluebeard (1988) and Hocus Pocus (1990). During the Second World War he was held prisoner in Germany and was present at the bombing of Dresden, an experience which provided the setting for his most famous work to date, Slaughterhouse Five (1969). He has also published a volume of autobiography entitled Palm Sunday (1981) and a collection of essays and speeches, Fates Worse Than Death (1991)."
#            >
#     >

victim2 = victim.next_targets.first.fire_at!

pp victim2.result 
# => {"title"=>"Slaughterhouse-Five",
#     "author"=>"Kurt Vonnegut",
#     "price"=>"$4.83",
#     "author_bio"=>"Kurt Vonnegut was born in Indianapolis in 1922. He studied at the universities of Chicago and Tennessee and later began to write short stories for magazines. His first novel, Player Piano, was published in 1951 and since then he has written many novels, among them: The Sirens of Titan (1959), Mother Night (1961), Cat's Cradle (1963), God Bless You Mr Rosewater (1964), Welcome to the Monkey House; a collection of short stories (1968), Breakfast of Champions (1973), Slapstick, or Lonesome No More (1976), Jailbird (1979), Deadeye Dick (1982), Galapagos (1985), Bluebeard (1988) and Hocus Pocus (1990). During the Second World War he was held prisoner in Germany and was present at the bombing of Dresden, an experience which provided the setting for his most famous work to date, Slaughterhouse Five (1969). He has also published a volume of autobiography entitled Palm Sunday (1981) and a collection of essays and speeches, Fates Worse Than Death (1991)."
#    }
```

Look at samples/04_context.rb for complete sample.

## 5. Auto-fire: don't make me think of targets!

Cobb allows you to define gun target, while describing the gun.
Like this:

```ruby
class Vonneguth < Cobb::Gun
  target 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
  
  def mechanizm
    bio = html.at!('#artistCentralBio_officialFullBioContent').text
    
    html.css('#mainResults .result').each do |row|
      next_to Book, row.at!('h3.title a').href
    end
  end
end
```

Now, if you really wanted only Vonnegut's books (and why you shouldn't?),
you can just:

```ruby
victims = Amazon::Vonneguth.auto_fire # without any URL
pp victims.map(&:next_orders).flatten
# => [#<Cobb::Target: Amazon::Book.fire(http://www.amazon.com/Slaughterhouse-Five-Kurt-Vonnegut/dp/0440180295) with #<Cobb::Mash author_bio="Kurt Vonnegut was born in Indianapolis in 1922. He studied at the universities of Chicago and Tennessee and later began to write short stories for magazines. His first novel, Player Piano, was published in 1951 and since then he has written many novels, among them: The Sirens of Titan (1959), Mother Night (1961), Cat's Cradle (1963), God Bless You Mr Rosewater (1964), Welcome to the Monkey House; a collection of short stories (1968), Breakfast of Champions (1973), Slapstick, or Lonesome No More (1976), Jailbird (1979), Deadeye Dick (1982), Galapagos (1985), Bluebeard (1988) and Hocus Pocus (1990). During the Second World War he was held prisoner in Germany and was present at the bombing of Dresden, an experience which provided the setting for his most famous work to date, Slaughterhouse Five (1969). He has also published a volume of autobiography entitled Palm Sunday (1981) and a collection of essays and speeches, Fates Worse Than Death (1991).">>,
#     #<Cobb::Target: Amazon::Book.fire(http://www.amazon.com/This-Isnt-Nice-What-Graduation/dp/1609805917) with #<Cobb::Mash author_bio="Kurt Vonnegut was born in Indianapolis in 1922. He studied at the universities of Chicago and Tennessee and later began to write short stories for magazines. His first novel, Player Piano, was published in 1951 and since then he has written many novels, among them: The Sirens of Titan (1959), Mother Night (1961), Cat's Cradle (1963), God Bless You Mr Rosewater (1964), Welcome to the Monkey House; a collection of short stories (1968), Breakfast of Champions (1973), Slapstick, or Lonesome No More (1976), Jailbird (1979), Deadeye Dick (1982), Galapagos (1985), Bluebeard (1988) and Hocus Pocus (1990). During the Second World War he was held prisoner in Germany and was present at the bombing of Dresden, an experience which provided the setting for his most famous work to date, Slaughterhouse Five (1969). He has also published a volume of autobiography entitled Palm Sunday (1981) and a collection of essays and speeches, Fates Worse Than Death (1991).">>,
#     ... and so on ...
```

The real miracles became later, when you want book:

```ruby
class Book < Cobb::Gun
  target Vonnegut # see?
  
  def mechanizm
    # as per previous examples
  end
end

# Aaaaand, without any preparations:
victims = Amazon::Book.auto_fire
```

In latter case, `auto_fire` would first run `Vonnegut.auto_fire`,
which extracts from its designated URL. Then we'll process all URLs which 
Vonnegut put in its `next_targets`.

See samples/05_auto_fire.rb for full example.

## 6. Vera: the cutest gun ever

> Six men came to kill me one time. And the best of 'em carried this. 
> It's a Callahan full-bore auto-lock. Customized trigger, double 
> cartridge thorough gauge. It is my very favorite gun … This is the best 
> gun made by man. It has extreme sentimental value … I call her Vera<br/>
> -- Jayne Cobb

The `auto_fire` is almost enough for little simple demonstration, but in
real, actual, factual world you need more. And here comes 
[Vera](http://firefly.wikia.com/wiki/Vera).

You just do something like:

```ruby
Cobb::Vera.new(Amazon::Book).birst!(progress: true)
```

And Vera does the things. She shows progress bars. She processeses cyclic
dependencies and checks every gun/url shot only once. 
She forces all gun in gun chain to be shot. She is beautiful. She is all
Cobb loves.

Assume this:

```ruby
class Vonneguth < Cobb::Gun
  target 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
  
  def mechanizm
    bio = html.at!('#artistCentralBio_officialFullBioContent').text
    
    html.css('#mainResults .result').each do |row|
      next_to Book, row.at!('h3.title a').href
    end

    html.at?('#pagn #pagnNextLink').tap{|a|
      next_to Vonnegut, a.href
    }
  end
end

# and then, just:
victims = Cobb::Vera.new(Amazon::Book).birst!(progress: true)
pp victims2.map(&:result)
```

(Full sample at samples/06_vera.rb is almost like this, but considering
some Amazon's gotchas.)

This example will example ALL of Vonnegut book listing pages 
(see at `next_to Vonnegut`), and only them extract books from them, and 
it will be all books from all the pages (while `Book.auto_fire` will
get you books from as least targets as it can).

Try it, I'm serious. Just give it a try.


## 7. What else Jayne Cobb does for me, if I pay enough?

### Train with your gun

### Settings

### Nokogiri::More

Nokogiri::More is, for now, a part of Cobb, though it will be separated
into different gem in nearest future. It's some extensions and monkey-patches
to Nokogiri, which makes it easier for complex production-ready parsers.

### Some useful shortcuts

* `repeat url [, context]` is just like `next_to` with same class (useful
  for paging and other such things);
  so in example 6 for Vera above we could just `repeat a.href` instead of
  `next_to Vonnegut, a.href`
* Cobb is not only for HTML pages parsing! `raw` is already here for every
  gun, containing raw request body, and `json` is calculated when you
  first call it and is equivalent to `JSON.parse(raw)`, if your requests
  are returning JSON (also, seems useful to provide `xml` alongside with
  `html` method, though I haven't done it yet)

## Current state of a gem

At the one hand, it's real 0.0.1: no specs, no docs in code, and some
solutions are questionable.

At the other hand, it's exctraction of real-world large production
project, and many different sites have seen my Vera.

At the third hand, while being extracted, it overcomed some rewritings 
and renamings, so, may be broken at a moment.

And the fourth hand, all examples are working.

Trust the view you like more, look at the code, write your opinions at
requests to zverok.offline@gmail.com.

## TODO

* Specs!!!
* Instead of dumb custom WebClient, just use Faraday cachin middleware
  and make it customizable
* Separate Nokogiri::More to another gem
* More settings
* More logs

## Requirements
