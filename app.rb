require 'sinatra'
require 'stripe'
require 'mail'
# require 'pry'
require_relative 'database'

Database.initialize

set :publishable_key, ENV['PUBLISHABLE_KEY']
set :secret_key, ENV['SECRET_KEY']
enable :sessions

Stripe.api_key = settings.secret_key

Mail.defaults do
  delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                           :port      => 587,
                           :domain    => "goattrips.org",
                           :user_name => "goattrips",
                           :password  => ENV['SENDGRID_PW'],
                           :authentication => 'plain',
                           :enable_starttls_auto => true }
end

get '/' do
  @donations = Donation.all
  @done = Donation.all(:paid => 'true')
  @total = 0
  @done.each do |done|
    @total += done.amount
  end
  erb :index
end

get '/goal' do
  @done = Donation.all(:paid => 'true')
  @total = 0
  @done.each do |done|
    @total += done.amount
  end
  erb :goal
end

post '/charge' do
  @donation = Donation.get(params[:donation_id])
  donation = @donation

  customer = Stripe::Customer.create(
    email: params[:email],
    card: params[:token_id]
  )

  begin
    Stripe::Charge.create(
      amount: @donation.amount*100,
      description: "200 Donors",
      currency: 'usd',
      customer: customer.id
    )

    @donation.update(paid: 'true')
    session[:id] = @donation.id
  rescue Stripe::CardError => e
    body = e.json_body
    session[:error] = body[:error][:message]
    halt 500
  end

  mail = Mail.deliver do
  
  to customer.email
  from 'Ryan McCrary <ryan@goattrips.org>'
  subject 'GOAT Christmas!'
  text_part do
    body "Thanks again for participating in GOAT Christmas! The end of the year is an important fundraising time for our organization and your giving helps set the stage for our programs next year! Your donation of $#{donation.amount} gets us closer to our goal!

We would love to send you a GOAT shirt (or coffee if shirts aren’t your thing) from our online store as our way of saying thank you! You can browse what we have available at http://www.goattrips.org/shop and you can use the code SANTAHAT2015 to get any item for free with free shipping. Get something for yourself, or grab something as a gift. 

We would love for you to share GOAT Christmas with your friends and family on facebook, twitter or instagram and help us reach our goal for Christmas!

Thanks again, and please let us know if we can answer any questions or thoughts about GOAT or GOAT Christmas! You can checkup on our progress at http://christmas.goattrips.org/goal

Merry Christmas,

Ryan McCrary and the GOAT Team


"
  end
  html_part do
    content_type 'text/html; charset=UTF-8'
    body "<p>Thanks again for participating in GOAT Christmas! The end of the year is an important fundraising time for our organization and your giving helps set the stage for our programs next year! Your donation of $#{donation.amount} gets us closer to our goal!</p>

<p>We would love to send you a GOAT shirt (or coffee if shirts aren’t your thing) from our online store as our way of saying thank you! You can browse what we have available at <a href='http://www.goattrips.org/shop'>our online shop</a> and you can use the code SANTAHAT2015 to get any item for free with free shipping. Get something for yourself, or grab something as a gift.</p>

<p>We would love for you to share GOAT Christmas with your friends and family on facebook, twitter or instagram and help us reach our goal for Christmas!</p>

<p>Thanks again, and please let us know if we can answer any questions or thoughts about GOAT or GOAT Christmas! You can checkup on our progress at <a href='http://christmas.goattrips.org/goal'>http://christmas.goattrips.org/goal</a></p>

<p>Merry Christmas,</p>

<p>Ryan McCrary and the GOAT Team</p><br /><br /><br />"
  end
  end

  halt 200
end

get '/thanks' do
  @error = session[:error]
  if @error
    halt erb(:thanks)
  end

  @donation = Donation.get(session[:id])

  paid_donations = Donation.all(paid: 'true')
  @total = 0
  paid_donations.each do |done|
    @total += done.amount
  end

  erb :thanks
end

__END__

@@ layout
  <!DOCTYPE html>
  <html>
  <head>
    <title>GOAT Christmas!</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
    <link rel='stylesheet' type='text/css' href='css/main.css'/>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
    <script src="https://checkout.stripe.com/checkout.js"></script>
    <meta property="og:image" content="http://christmas.goattrips.org/img/400x400.jpg" />
    <meta property="og:image:secure_url" content="https://christmas.goattrips.org/img/400x400.jpg" />
    <meta property="og:description" content="I participated in GOAT Christmas and you should too! If one person gives each of the values below from $1-200 we will raise just over $20,000 to kickstart our programs for 2016. GOAT would never happen without passionate people giving generously to changing lives in Greenville." />
    <link href='https://fonts.googleapis.com/css?family=Alegreya+Sans:400,700,800' rel='stylesheet' type='text/css'>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
  </head>
  <body>
    <%= yield %>
  <script type="text/javascript" src="https://use.typekit.net/cje3rie.js"></script>
  <script type="text/javascript">try{Typekit.load();}catch(e){}</script>
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-5502319-8', 'auto');
  ga('send', 'pageview');

</script>

  </body>
  </html>

@@index
  <header class="main-header">
    <div class="row">
      <h1>Give the Gift
        <span>of the Outdoors</span>
      </h1>
      <p class="description">Join us this Christmas to give the gift of the outdoors to someone who can’t get there on their own. Our goal is to have someone claim each of the values below by the end of the year. It’s simple - if every amount below is donated, we can raise $20,000 for our 2016 programs without a single person having to give over $200. So go ahead, pick your amount and give a life changing experience to a kid through GOAT!</p>
    </div>
  </header>


  <h2 class="donate-header">DONATE   TODAY</h2>

  <div class="bigbox">
    <% @donations.each do |donation| %>
      <% if donation.paid? %>
      <div class="giftbox complete material-icons"><span class="vertical-aligned">check</span></div>
      <!-- $<%= donation.amount %>.00 -->
      <% else %>
      <div class="giftbox">
        <div class="vertical-aligned">
          <form action="/charge" method="post">
            <button type="submit" class="donation-button" style="visibility: visible;" data-amount="<%= donation.amount*100 %>" data-id="<%= donation.id %>">$<%= donation.amount %></button>
          </form>
        </div>
      </div>
      <% end %>
    <% end %>
  </div>


  <div class="container">
    <div class="row footer">
      <div class="col-md-6">
        <p>To learn more about <a href="http://goattrips.org">GOAT</a>, you can visit our website at <a href="http://goattrips.org">goattrips.org</a> or on <a href="http://facebook.com/goattrips">facebook</a>.</p>
        <p>All donations are processed securely by <a href="http://stripe.com">Stripe</a>.</p>
      </div>
    </div>
  </div>

  <script>
    $('.giftbox').on('click', 'button', function(e) {
      e.preventDefault();
      $this = $(this);

      var handler = StripeCheckout.configure({
        key: '<%= settings.publishable_key %>',
        name: "Great Outdoor Adventure Trips",
        image: 'img/160x160.jpg',
        allowRememberMe: 'false',
        billingAddress: 'true',
        amount: $this.data('amount'),
        closed: function() {
        },
        token: function(token) {
          $.post( "/charge", {
            token_id: token.id,
            donation_id: $this.data('id'),
            email: token.email
          }).done(function() {
            window.location.href = "/thanks";
          }).fail(function() {
            alert( "Sorry! There was an error processing your donation." );
          });
        }
      });

      handler.open();
    });
  </script>

@@thanks
<div id="fb-root"></div>
<script>(function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/sdk.js#xfbml=1&version=v2.0";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));</script>
<script>$('body').addClass('thanks');</script>
<header class="thanks-header">
  <div class="container">
    <h1>Thanks so much for being a part of GOAT Christmas!</h1>
  </div>
</header>

<div class="container thanks-details">
  <h3 class="donation-message">Your donation of <span class="your-donation">$<%= @donation.amount %></span> brings the total to <span class="donation-total">$<%= @total %></span>!</h3>
  <p class="details">We would love to send you a <strong>free GOAT shirt</strong> as our way of saying thanks! Check your email for a details on your free shirt and make sure to share <a href="http://twitter.com/#goatchristmas" target="_blank">#goatchristmas</a> with your friends - the more the merrier!</p>
  <div class="details">&larr; <a href="/">Click here to see the whole fundraiser with your amount taken!</a></p>
</div>


@@goal
<script>$('body').addClass('goal');</script>
<div class="goal-container">
  <div class="goal-details">
    <h4 class="flex-item">Our Christmas goal is currently at:</h4>
    <h1 class="flex-item goal-numbers-totals"><b class="goal-numbers">$<%= @total %></b> of <b class="goal-numbers">$20,100</b></h1>
      <div class="progress">
        <div class="progress-bar progress-bar-success" role="progressbar" aria-valuenow="40" aria-valuemin="0" aria-valuemax="100" style="width: <%= (@total/20000.0*100).round %>%;">
          <%= (@total/20000.0*100).round %>%
        </div>
      </div>
    <p class="flex-item">(from <%= @done.count %> donations)</p>
    <p class="flex-item"><a href="/">Return to GOAT Christmas</a></p>
  </div>
</div>
