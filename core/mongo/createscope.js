// create the group scope in the Manage database
db = db.getSiblingDB("manage");
db.runCommand({
   insert: "scopes", 
   documents: [ { 
      version: Long('0'), 
      name: 'groups', 
      titles: {en: 'groups'}, 
      descriptions: {en: 'voot group memberships'},
      _class: 'manage.model.Scope'
   }]
  }
)
