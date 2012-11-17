# Runivedo - Univedo Ruby Binding 

## Installation

Add this line to your application's Gemfile:

    gem 'runivedo'

## Usage

    connection = Runivedo.new(host: "univedo://hostname.com/bucket",
                              user: "username",
                              password: "secret",
                              uts: File.open("univedo.uts"))
    
    connection.prepare("SELECT * FROM tbl WHERE name = :name")
    connection.bind(:name, "foobar")
    result = connection.execute
    result.each do { |r| puts r[0], r[1] }

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
