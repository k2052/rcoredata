# Details

Provides a decorative AR-esque layer over CoreData so you can do stuff like: 
      
```ruby
p = Post.create()    

p.title = "Post Title"
p.date  = NSDate.date
p.body  = "CoreData is the confusing shit!"
p.save  

posts = Post.all       

a = Animal.create({:name => 'OctoCat'})   
a.save
```        

Although RCoreData makes everything much easier I recommended that you read up on CoreData and familiarize yourself anyway. Bugs in abstraction are fucking frustrating to solve when you don't understand what the magic is doing.                  

# Installation

Git clone into lib and `require 'lib/rcoredata/rcoredata'`. Sorry, no macgem at the moment; I'll do that eventually. 

You'll need to make sure a compiled .mom for your CoreData models ends up `AppName.app/Resources/AppName.mom`.

If you're using HotCocoa (and who isn't?) you just have to add the info for your data models to your app-spec and then HotCocoa will copy it over and compile when you run MacRake.

```ruby
s.data_models = %W{data/AppName.xcdatamodel}
```
# Usage 

Create your models using XCode then extend `RCoreData::Model` 

```ruby     
class Post < RCoreData::Model      
end
```      

It automagically creates model objects and the ManagedObjectContext will sit in model_instance.moc
        
## Save/delete 

- Save: `model.save()`
- Delete: `model.delete`
    
## Queries 
 
Simple find query:

```ruby        
class Account < RCoreData::Model       
  def self.find_account_by_email(email)    
    query  = "email == '#{email}'"  
    moc    = RCoreData::DataStore.find_by_entity_name("Account", 1, nil, query)   
    entity = NSEntityDescription.entityForName("Account",
      inManagedObjectContext:RCoreData::DataStore.moc)       
     
    return self.create_model_object(entity, moc[0])
  end 
end
```      

## Misc

Name method. The CoreData mom for account doesn't have a name field, only first_name and last_name.

```ruby   
class Account < RCoreData::Model 
  def name=(name)     
    n = name.split(",").join(" ").split(" ").uniq     
    if n.length > 0
      self.first_name = n[0] 
      self.last_name  = n[1]            
    else
      self.first_name = n[0] 
    end           
  end   
end
```     

# Examples

- Simple Post/Blog app: Provides a list of Posts and CRUD; and that is all. 
  [https://github.com/bookworm/rcoredata_demo_blog](https://github.com/bookworm/rcoredata_demo_blog)

# License

License under Do What The Fuck You Want To Public License [http://sam.zoy.org/wtfpl/](http://sam.zoy.org/wtfpl/). AKA The don't be an asshole license.

## Support

If you found this repo useful please consider supporting me on [Gittip](https://www.gittip.com/k2052) or sending me some
bitcoin `1csGsaDCFLRPPqugYjX93PEzaStuqXVMu`
