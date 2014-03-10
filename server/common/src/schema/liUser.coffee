mongoose = require 'mongoose'
Schema = mongoose.Schema

utils = require '../lib/utils'

#TODO: remove mixed types!
LIUser = new Schema
  _id: {type: String, required: true, unique: true}

  #tokens
  accessTokenEncrypted: {type: String}
  accessTokenIV: {type: String}
  
  #profile data
  educations: Schema.Types.Mixed
  emailAddress: {type: String}
  firstName: {type: String}
  lastName: {type: String}
  formattedName: {type: String}
  following: Schema.Types.Mixed
  headline: {type: String}
  industry: {type: String}
  jobBookmarks: Schema.Types.Mixed
  location: Schema.Types.Mixed
  numConnections: {type: Number}
  pictureUrl: {type: String}
  positions: Schema.Types.Mixed
  publicProfileUrl: {type: String}
  recommendationsReceived: Schema.Types.Mixed
  siteStandardProfileRequest: {type: String}
  skills: Schema.Types.Mixed
  specialties: {type: String}
  summary: {type: String}
  threeCurrentPositions: Schema.Types.Mixed
  threePastPositions: Schema.Types.Mixed


LIUser.virtual('accessToken').set (input) ->
  encryptedInfo = utils.encryptSymmetric input
  this.accessTokenEncrypted = encryptedInfo.encrypted
  this.accessTokenIV = encryptedInfo.iv

LIUser.virtual('accessToken').get () ->
  decrypted = utils.decryptSymmetric this.accessTokenEncrypted, this.accessTokenIV
  decrypted

mongoose.model 'LIUser', LIUser
exports.LIUserModel = mongoose.model 'LIUser'

### Connection
  "apiStandardProfileRequest": {
    "headers": {
      "_total": 1,
      "values": [
        {
          "name": "x-li-auth-token",
          "value": "name:4Tkp"
        }
      ]
    },
    "url": "http://api.linkedin.com/v1/people/rxaAopnA1Q"
  },
  "firstName": "Caroline",
  "headline": "Director of Platform and Product Development at Fullbridge",
  "id": "rxaAopnA1Q",
  "industry": "Higher Education",
  "lastName": "Young",
  "location": {
    "country": {
      "code": "us"
    },
    "name": "Greater Boston Area"
  },
  "pictureUrl": "http://m.c.lnkd.licdn.com/mpr/mprx/0_OYjMBBzvE8k_GfepyUaEBzXFHkimCuJpyMd6BqbFcbcYgHaytZDvJN1d62_l3w4r0g0bZPzVtZ60",
  "siteStandardProfileRequest": {
    "url": "http://www.linkedin.com/profile/view?id=16538469&authType=name&authToken=4Tkp&trk=api*a3601921*s3673761*"
  }
###


### FULL profile
apiStandardProfileRequest": {
      "headers": {
        "_total": 1,
        "values": [
          {
            "name": "x-li-auth-token",
            "value": "name:9Ppr"
          }
        ]
      },
      "url": "http://api.linkedin.com/v1/people/kN9wC_VznU"
    },
    "distance": 0,
    "educations": {
      "_total": 3,
      "values": [
        {
          "degree": "M.B.A.",
          "endDate": {
            "year": 2012
          },
          "fieldOfStudy": "",
          "id": 55271052,
          "notes": "Granted a Certificate in Public Management and Social Innovation",
          "schoolName": "Stanford University Graduate School of Business",
          "startDate": {
            "year": 2010
          }
        },
        {
          "degree": "M.S.",
          "endDate": {
            "year": 2005
          },
          "fieldOfStudy": "Computer Science",
          "id": 7203653,
          "schoolName": "Stanford University",
          "startDate": {
            "year": 2004
          }
        },
        {
          "degree": "B.S.",
          "endDate": {
            "year": 2004
          },
          "fieldOfStudy": "Computer Systems Engineering",
          "id": 7203340,
          "schoolName": "Stanford University",
          "startDate": {
            "year": 2000
          }
        }
      ]
    },
    "emailAddress": "jdurack@gmail.com",
    "firstName": "Justin",
    "following": {
      "companies": {
        "_total": 1,
        "values": [
          {
            "id": 1441,
            "name": "Google"
          }
        ]
      },
      "industries": {
        "_total": 1,
        "values": [
          {
            "id": 4
          }
        ]
      },
      "people": {
        "_total": 0
      },
      "specialEditions": {
        "_total": 0
      }
    },
    "formattedName": "Justin Durack",
    "headline": "Entrepreneur",
    "id": "kN9wC_VznU",
    "industry": "Computer Software",
    "jobBookmarks": {
      "_total": 0
    },
    "lastModifiedTimestamp": 1390866701403,
    "lastName": "Durack",
    "location": {
      "country": {
        "code": "us"
      },
      "name": "San Francisco Bay Area"
    },
    "memberUrlResources": {
      "_total": 0
    },
    "mfeedRssUrl": "http://www.linkedin.com/rss/mefeed?key=HsnppN2D9uTWTIDc95nMmdQGf7lPFNqVvmRSJQg6S0L3aaOQbI5cVnMT-0FlHMS",
    "numConnections": 500,
    "numConnectionsCapped": true,
    "numRecommenders": 0,
    "pictureUrl": "http://m.c.lnkd.licdn.com/mpr/mprx/0_N0TLAX1nil0YDZCjNMC9AbtUTAD03RCj9OvsAbCIY-JfOxvg4JldxF9L7MShCp_Avp_ROhyBRACY",
    "positions": {
      "_total": 4,
      "values": [
        {
          "company": {
            "industry": "Computer Software",
            "name": "Sidekick Labs"
          },
          "id": 369309746,
          "isCurrent": true,
          "startDate": {
            "month": 1,
            "year": 2013
          },
          "title": "Co-founder"
        },
        {
          "company": {
            "id": 1441,
            "industry": "Internet",
            "name": "Google",
            "size": "10,001+ employees",
            "ticker": "GOOG",
            "type": "Public Company"
          },
          "endDate": {
            "month": 8,
            "year": 2011
          },
          "id": 200115083,
          "isCurrent": false,
          "startDate": {
            "month": 6,
            "year": 2011
          },
          "summary": "Music partner and reporting team at YouTube.",
          "title": "Product Manager MBA Intern"
        },
        {
          "company": {
            "id": 2189816,
            "industry": "Marketing and Advertising",
            "name": "Lift Media, Inc"
          },
          "endDate": {
            "month": 4,
            "year": 2010
          },
          "id": 14887261,
          "isCurrent": false,
          "startDate": {
            "month": 4,
            "year": 2007
          },
          "summary": "Built a web commerce platform, leading to company acquisition.\nCo-led an eleven person engineering team.",
          "title": "Director of Engineering"
        },
        {
          "company": {
            "id": 1062,
            "industry": "Computer Software",
            "name": "Sun Microsystems",
            "size": "10,001+ employees",
            "ticker": "JAVA",
            "type": "Public Company"
          },
          "endDate": {
            "month": 4,
            "year": 2007
          },
          "id": 21833121,
          "isCurrent": false,
          "startDate": {
            "month": 9,
            "year": 2005
          },
          "summary": "Software Engineer for the StreamSTAR team within the Systems Group.  Responsible for producing server side applications for a Video on Demand solution. Part of a small, motivated team working to maximize system stability and usability.  Day to day work includes developing new system features and test infrastructure by following a short-cycle, test-driven  methodology.  Development primarily in C++, TCL and Python in a Linux environment.",
          "title": "Software Engineer"
        }
      ]
    },
    "publicProfileUrl": "http://www.linkedin.com/pub/justin-durack/3/789/674",
    "recommendationsReceived": {
      "_total": 0
    },
    "relatedProfileViews": {
      "_total": 10,
      "values": [
        {
          "firstName": "Sagar",
          "id": "p-ZQj0j_Xd",
          "lastName": "Mehta"
        },
        {
          "firstName": "Andrew",
          "id": "g0QTxhFu2d",
          "lastName": "Lockhart"
        },
        {
          "firstName": "Jérôme",
          "id": "-o6jY2munv",
          "lastName": "P."
        },
        {
          "firstName": "Mudit",
          "id": "IwdgUkggbd",
          "lastName": "Garg"
        },
        {
          "firstName": "Cody",
          "id": "n9LchPpHQb",
          "lastName": "Veal"
        },
        {
          "firstName": "Charlie",
          "id": "2RzJzc-Rwj",
          "lastName": "Kubal"
        },
        {
          "firstName": "Bastiaan",
          "id": "0Isfj5LJzz",
          "lastName": "Janmaat"
        },
        {
          "firstName": "Noah",
          "id": "cTYbElI6Km",
          "lastName": "Lichtenstein"
        },
        {
          "firstName": "Sameh",
          "id": "dUUurIrLG8",
          "lastName": "Elamawy"
        },
        {
          "firstName": "private",
          "id": "private",
          "lastName": "private"
        }
      ]
    },
    "relationToViewer": {
      "distance": 0
    },
    "siteStandardProfileRequest": {
      "url": "http://www.linkedin.com/profile/view?id=10882168&authType=name&authToken=9Ppr&trk=api*a3601921*s3673761*"
    },
    "skills": {
      "_total": 23,
      "values": [
        {
          "id": 2,
          "skill": {
            "name": "Software Development"
          }
        },
        {
          "id": 3,
          "skill": {
            "name": "Software Engineering"
          }
        },
        {
          "id": 4,
          "skill": {
            "name": "Scalability"
          }
        },
        {
          "id": 5,
          "skill": {
            "name": "Product Management"
          }
        },
        {
          "id": 6,
          "skill": {
            "name": "Entrepreneurship"
          }
        },
        {
          "id": 7,
          "skill": {
            "name": "C++"
          }
        },
        {
          "id": 8,
          "skill": {
            "name": "C"
          }
        },
        {
          "id": 9,
          "skill": {
            "name": "PHP"
          }
        },
        {
          "id": 10,
          "skill": {
            "name": "MySQL"
          }
        },
        {
          "id": 11,
          "skill": {
            "name": "Java"
          }
        },
        {
          "id": 12,
          "skill": {
            "name": "HTML"
          }
        },
        {
          "id": 13,
          "skill": {
            "name": "XML"
          }
        },
        {
          "id": 14,
          "skill": {
            "name": "CSS"
          }
        },
        {
          "id": 15,
          "skill": {
            "name": "Linux"
          }
        },
        {
          "id": 16,
          "skill": {
            "name": "Apache"
          }
        },
        {
          "id": 17,
          "skill": {
            "name": "AJAX"
          }
        },
        {
          "id": 18,
          "skill": {
            "name": "Product Development"
          }
        },
        {
          "id": 19,
          "skill": {
            "name": "Mobile"
          }
        },
        {
          "id": 20,
          "skill": {
            "name": "Start-ups"
          }
        },
        {
          "id": 23,
          "skill": {
            "name": "Mobile Devices"
          }
        },
        {
          "id": 24,
          "skill": {
            "name": "Big Data"
          }
        },
        {
          "id": 25,
          "skill": {
            "name": "Mobile Applications"
          }
        },
        {
          "id": 26,
          "skill": {
            "name": "Test Driven Development"
          }
        }
      ]
    },
    "specialties": "entrepreneurship, software development, software architecture, scalability",
    "suggestions": {
      "toFollow": {
        "companies": {
          "_count": 10,
          "_start": 0,
          "values": [
            {
              "id": 1791,
              "name": "Stanford Graduate School of Business"
            },
            {
              "id": 1792,
              "name": "Stanford University"
            },
            {
              "id": 741690,
              "name": "This Week in Startups"
            },
            {
              "id": 10667,
              "name": "Facebook"
            },
            {
              "id": 2260935,
              "name": "York Angel Investors"
            },
            {
              "id": 2299227,
              "name": "Hellenic Start-up Association"
            },
            {
              "id": 1965132,
              "name": "TechBA Silicon Valley"
            },
            {
              "id": 1670880,
              "name": "Startup Monthly"
            },
            {
              "id": 1371,
              "name": "McKinsey & Company"
            },
            {
              "id": 551053,
              "name": "westartup"
            }
          ]
        },
        "industries": {
          "_total": 25,
          "values": [
            {
              "id": 6
            },
            {
              "id": 8
            },
            {
              "id": 109
            },
            {
              "id": 80
            },
            {
              "id": 11
            },
            {
              "id": 113
            },
            {
              "id": 104
            },
            {
              "id": 43
            },
            {
              "id": 99
            },
            {
              "id": 124
            },
            {
              "id": 28
            },
            {
              "id": 57
            },
            {
              "id": 41
            },
            {
              "id": 68
            },
            {
              "id": 98
            },
            {
              "id": 14
            },
            {
              "id": 137
            },
            {
              "id": 44
            },
            {
              "id": 27
            },
            {
              "id": 69
            },
            {
              "id": 106
            },
            {
              "id": 100
            },
            {
              "id": 30
            },
            {
              "id": 19
            },
            {
              "id": 48
            }
          ]
        },
        "newsSources": {
          "_total": 25,
          "values": [
            {
              "id": 10000208,
              "name": "regalspri.com"
            },
            {
              "id": 10000075,
              "name": "thedeal.com"
            },
            {
              "id": 10000145,
              "name": "lynda.com"
            },
            {
              "id": 1000333,
              "name": "nrn.com"
            },
            {
              "id": 1000281,
              "name": "computerworld.com"
            },
            {
              "id": 1000402,
              "name": "business2community.com"
            },
            {
              "id": 10000140,
              "name": "cfo.com"
            },
            {
              "id": 1000076,
              "name": "ft.com"
            },
            {
              "id": 10000137,
              "name": "radar.oreilly.com"
            },
            {
              "id": 1000276,
              "name": "businessoffashion.com"
            },
            {
              "id": 10000044,
              "name": "webpronews.com"
            },
            {
              "id": 10000180,
              "name": "iexpats.com"
            },
            {
              "id": 1000427,
              "name": "investors.com"
            },
            {
              "id": 10000037,
              "name": "canadianbusiness.com"
            },
            {
              "id": 10000039,
              "name": "investmentreview.com"
            },
            {
              "id": 1000054,
              "name": "dsnews.com"
            },
            {
              "id": 1000191,
              "name": "slashfilm.com"
            },
            {
              "id": 1000374,
              "name": "eweek.com"
            },
            {
              "id": 1000451,
              "name": "journaldunet.com"
            },
            {
              "id": 10000225,
              "name": "dailybeast.com"
            },
            {
              "id": 1000250,
              "name": "dealbook.nytimes.com"
            },
            {
              "id": 1000440,
              "name": "financialpost.com"
            },
            {
              "id": 10000115,
              "name": "pcworld.com"
            },
            {
              "id": 1000175,
              "name": "retail-week.com"
            },
            {
              "id": 1000106,
              "name": "latimes.com"
            }
          ]
        },
        "people": {
          "_total": 0
        }
      }
    },
    "summary": "Building great products.",
    "threeCurrentPositions": {
      "_total": 1,
      "values": [
        {
          "company": {
            "industry": "Computer Software",
            "name": "Sidekick Labs"
          },
          "id": 369309746,
          "isCurrent": true,
          "startDate": {
            "month": 1,
            "year": 2013
          },
          "title": "Co-founder"
        }
      ]
    },
    "threePastPositions": {
      "_total": 3,
      "values": [
        {
          "company": {
            "id": 1441,
            "industry": "Internet",
            "name": "Google",
            "size": "10,001+ employees",
            "ticker": "GOOG",
            "type": "Public Company"
          },
          "endDate": {
            "month": 8,
            "year": 2011
          },
          "id": 200115083,
          "isCurrent": false,
          "startDate": {
            "month": 6,
            "year": 2011
          },
          "summary": "Music partner and reporting team at YouTube.",
          "title": "Product Manager MBA Intern"
        },
        {
          "company": {
            "id": 2189816,
            "industry": "Marketing and Advertising",
            "name": "Lift Media, Inc"
          },
          "endDate": {
            "month": 4,
            "year": 2010
          },
          "id": 14887261,
          "isCurrent": false,
          "startDate": {
            "month": 4,
            "year": 2007
          },
          "summary": "Built a web commerce platform, leading to company acquisition.\nCo-led an eleven person engineering team.",
          "title": "Director of Engineering"
        },
        {
          "company": {
            "id": 1062,
            "industry": "Computer Software",
            "name": "Sun Microsystems",
            "size": "10,001+ employees",
            "ticker": "JAVA",
            "type": "Public Company"
          },
          "endDate": {
            "month": 4,
            "year": 2007
          },
          "id": 21833121,
          "isCurrent": false,
          "startDate": {
            "month": 9,
            "year": 2005
          },
          "summary": "Software Engineer for the StreamSTAR team within the Systems Group.  Responsible for producing server side applications for a Video on Demand solution. Part of a small, motivated team working to maximize system stability and usability.  Day to day work includes developing new system features and test infrastructure by following a short-cycle, test-driven  methodology.  Development primarily in C++, TCL and Python in a Linux environment.",
          "title": "Software Engineer"
        }
      ]
    }
  }
}

###