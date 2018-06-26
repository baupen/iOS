// Created by Julian Dunskus

import Foundation

let json = """
{
  "changedCraftsmen": [
    {
      "name": "Mario Casanova (Kunz AG)",
      "trade": "Lüftungsanlagen",
      "meta": {
        "id": "043524AC-BBAF-40C9-856B-61C9503830A8",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Thomas Kuster (Kuster + Partner AG)",
      "trade": "Bauphysiker",
      "meta": {
        "id": "333E88C9-7CF0-4F0F-A32E-050F0E0DC038",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Sandro Darms (Marco Felix AG)",
      "trade": "Sanitäringenieur",
      "meta": {
        "id": "4E28156C-A05E-43BC-8B14-C7550D31ECFB",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Hans-Peter Hoffmann (Baulink AG)",
      "trade": "Projektleitung",
      "meta": {
        "id": "55E1A856-AABD-4E59-AE7C-442781B4B39B",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "René Wildhaber (Wildhaber Elektroplanung AG)",
      "trade": "Elektroingenieur",
      "meta": {
        "id": "606CE558-DCB2-45BC-850E-540A639184D3",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Dominic Koch (Baulink AG)",
      "trade": "Bauleitung",
      "meta": {
        "id": "8B89443F-D369-4998-B985-FA9862A6B416",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Janine Bernhard (Bernhard Holzbau AG)",
      "trade": "Kücheneinrichtungen",
      "meta": {
        "id": "93561805-8EA4-4FC1-AEA4-129B5E07652C",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Celso Duarte (Elekto Rhyner AG)",
      "trade": "Elektroinstallationen",
      "meta": {
        "id": "AC80A96A-411F-4509-AF39-5781C0DE54EA",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Rico Buchli (Kunz AG)",
      "trade": "Sanitäranlagen",
      "meta": {
        "id": "BAE2336D-9D1A-4493-A92B-1FE5004AA0FF",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Remo Collenberg (Remo Collenberg)",
      "trade": "Heizungsingeneiur",
      "meta": {
        "id": "BD1B7ED6-A87E-4999-AE7E-026EC68206B1",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Flurina Rüesch (Baulink AG)",
      "trade": "Hochbauzeichner",
      "meta": {
        "id": "CBBC690A-CBFB-494B-9188-1AED2BB363EE",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Alek Tobler (Kunz AG)",
      "trade": "Heizungsanlagen",
      "meta": {
        "id": "D92600BD-653B-4351-BC61-01598BC37220",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Remo Caprez (Schindler Aufzüge AG)",
      "trade": "Transportanlagen / Aufzüge",
      "meta": {
        "id": "E0D76132-D223-4D9D-B700-8AE397E699CF",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Patrick Hager (Toneatti AG)",
      "trade": "Baumeisterarbeiten",
      "meta": {
        "id": "E3A50FC8-6F4D-437D-A95E-98CC8FDD3931",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "name": "Paul Schweighauser (Davoser Ingenieure AG (DIAG))",
      "trade": "Bauingenieur",
      "meta": {
        "id": "EA0C45B1-17AF-40CC-BD1C-AFC17D9338A0",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    }
  ],
  "removedCraftsmanIDs": [],
  "changedBuildings": [
    {
      "name": "Sun Park",
      "address": {
        "streetAddress": "Parkstrasse 12",
        "postalCode": 7270,
        "locality": "Davos",
        "country": "CH"
      },
      "imageFilename": "upload/B040DBBE-9825-4D67-814A-F5CC85CDAEAC/cab4da36-f0d9-44eb-be72-157e2f85161f.jpg",
      "maps": [
        "4D4000B3-635E-4123-881D-A13A4F0EE6CB",
        "58141DC5-7B76-4A0C-8450-68B53838934C",
        "E5EB2EE7-DEDC-44F3-ADC5-935A27D090AD",
        "1C2F2551-ECD7-426E-B3FB-09A8E2A00902",
        "76F4466E-3CA5-4422-A7A4-2F312145AF17"
      ],
      "craftsmen": [
        "CBBC690A-CBFB-494B-9188-1AED2BB363EE",
        "8B89443F-D369-4998-B985-FA9862A6B416",
        "55E1A856-AABD-4E59-AE7C-442781B4B39B",
        "EA0C45B1-17AF-40CC-BD1C-AFC17D9338A0",
        "606CE558-DCB2-45BC-850E-540A639184D3",
        "BD1B7ED6-A87E-4999-AE7E-026EC68206B1",
        "4E28156C-A05E-43BC-8B14-C7550D31ECFB",
        "333E88C9-7CF0-4F0F-A32E-050F0E0DC038",
        "E3A50FC8-6F4D-437D-A95E-98CC8FDD3931",
        "AC80A96A-411F-4509-AF39-5781C0DE54EA",
        "D92600BD-653B-4351-BC61-01598BC37220",
        "043524AC-BBAF-40C9-856B-61C9503830A8",
        "BAE2336D-9D1A-4493-A92B-1FE5004AA0FF",
        "93561805-8EA4-4FC1-AEA4-129B5E07652C",
        "E0D76132-D223-4D9D-B700-8AE397E699CF"
      ],
      "meta": {
        "id": "B040DBBE-9825-4D67-814A-F5CC85CDAEAC",
        "lastChangeTime": "2018-06-24T18:06:52+02:00"
      }
    },
    {
      "name": "Sun Park (empty)",
      "address": {
        "streetAddress": "Parkstrasse 12",
        "postalCode": 7270,
        "locality": "Davos",
        "country": "CH"
      },
      "imageFilename": "upload/FAA257B3-3165-4DD2-BB02-9FA88B87C507/3bc6f66e-651c-443e-bb25-a4622306a474.jpg",
      "maps": [],
      "craftsmen": [],
      "meta": {
        "id": "FAA257B3-3165-4DD2-BB02-9FA88B87C507",
        "lastChangeTime": "2018-06-24T18:06:52+02:00"
      }
    }
  ],
  "removedBuildingIDs": [],
  "changedMaps": [
    {
      "name": "2OG linker Bereich",
      "filename": "fb252a91-82c9-43ee-86cd-09d88c282154.pdf",
      "filePath": "fb252a91-82c9-43ee-86cd-09d88c282154.pdf",
      "children": [],
      "issues": [
        "17564BCC-75AE-4FA6-AEBC-EB6C4F6DB6DA",
        "ABB71096-5501-42DD-9333-33719853950E",
        "EC2D426B-2C0D-44AB-A2FA-D3306ED32E9F",
        "790D7BC9-DDE8-49BB-ADCD-916FFE2D3817",
        "60F3C74C-5A39-43B8-9A7B-63B71EDE4ABF"
      ],
      "meta": {
        "id": "1C2F2551-ECD7-426E-B3FB-09A8E2A00902",
        "lastChangeTime": "2018-06-24T18:06:55+02:00"
      }
    },
    {
      "name": "1UG",
      "filename": "8ddb1f13-d882-48ed-bc10-1c77da0df0b3.pdf",
      "filePath": "8ddb1f13-d882-48ed-bc10-1c77da0df0b3.pdf",
      "children": [],
      "issues": [
        "7545C248-1987-4226-B0C3-BDB5B899C1DB",
        "F7139EDA-4848-489E-A62D-86D6FDAB1F9A",
        "4D02AE0E-4FE4-4554-8061-75E8151E4743",
        "D0ACEB13-4BBE-46A3-B4C5-71444CA1B04A",
        "EA5B0718-58D1-4213-8372-4FD37F1580FF"
      ],
      "meta": {
        "id": "4D4000B3-635E-4123-881D-A13A4F0EE6CB",
        "lastChangeTime": "2018-06-24T18:06:54+02:00"
      }
    },
    {
      "name": "2OG",
      "filename": "b41d3ddb-2c03-44a7-8bdc-3c0d0ac3e4f4.pdf",
      "filePath": "b41d3ddb-2c03-44a7-8bdc-3c0d0ac3e4f4.pdf",
      "children": [
        "76F4466E-3CA5-4422-A7A4-2F312145AF17",
        "1C2F2551-ECD7-426E-B3FB-09A8E2A00902",
        "E5EB2EE7-DEDC-44F3-ADC5-935A27D090AD"
      ],
      "issues": [
        "A5E2539C-6D6B-48B7-A728-58750DFC67E8",
        "C2169264-2CE4-4FDC-8249-787898444047",
        "C8892B9F-77B9-494D-A5B8-DDB06B3D022E",
        "1D4A991A-4686-4B88-9FE1-1E0CBB0651B3",
        "F1D5FA5F-DB1A-460D-A530-F91D39494311"
      ],
      "meta": {
        "id": "58141DC5-7B76-4A0C-8450-68B53838934C",
        "lastChangeTime": "2018-06-24T18:06:55+02:00"
      }
    },
    {
      "name": "2OG rechter Bereich",
      "filename": "013b93bc-4a8f-4794-9cc8-a587a2b7669b.pdf",
      "filePath": "013b93bc-4a8f-4794-9cc8-a587a2b7669b.pdf",
      "children": [],
      "issues": [
        "7E976DF3-32DF-467C-BBB0-9B3620D0B3BF",
        "22B640B1-1372-4093-BE07-1F5EF31613FF",
        "7F4B82E3-DB15-404A-8533-D1B8C76B235F",
        "17519715-08AF-4784-A9FA-9C074979D5FB",
        "2C911F3F-279A-43E7-829B-153786982407"
      ],
      "meta": {
        "id": "76F4466E-3CA5-4422-A7A4-2F312145AF17",
        "lastChangeTime": "2018-06-24T18:06:55+02:00"
      }
    },
    {
      "name": "2OG Treppenhaus",
      "filename": "124f2132-4c41-4509-bd61-344909d18836.pdf",
      "filePath": "124f2132-4c41-4509-bd61-344909d18836.pdf",
      "children": [],
      "issues": [
        "B2915DC5-7476-4257-8BBA-7C26520EDC50",
        "116C9C36-BED3-4466-B3B5-9AB13E51090D",
        "D352E066-6FF0-40DA-A3A3-56F418974C54",
        "C1EEB63D-7FD9-4CE8-B7CC-38F1EEB27D0C",
        "0DCE1A4D-36DC-4F04-BE8B-63C3753F8886"
      ],
      "meta": {
        "id": "E5EB2EE7-DEDC-44F3-ADC5-935A27D090AD",
        "lastChangeTime": "2018-06-24T18:06:56+02:00"
      }
    }
  ],
  "removedMapIDs": [],
  "changedIssues": [
    {
      "number": 25,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand (new)",
      "craftsman": "AC80A96A-411F-4509-AF39-5781C0DE54EA",
      "imageFilename": "0a035a5a-0fd7-4775-b9a3-e7a155690f51.jpg",
      "status": {
        "registration": null,
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "E5EB2EE7-DEDC-44F3-ADC5-935A27D090AD",
      "meta": {
        "id": "0DCE1A4D-36DC-4F04-BE8B-63C3753F8886",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 10,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Steckdose eingedrückt",
      "craftsman": "AC80A96A-411F-4509-AF39-5781C0DE54EA",
      "imageFilename": "009bde95-44c6-4dea-a38e-70dbee737fff.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Celso Duarte (Elekto Rhyner AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:57+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.1,
        "y": 0.1,
        "zoomScale": 0.2
      },
      "map": "E5EB2EE7-DEDC-44F3-ADC5-935A27D090AD",
      "meta": {
        "id": "116C9C36-BED3-4466-B3B5-9AB13E51090D",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 18,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand",
      "craftsman": "55E1A856-AABD-4E59-AE7C-442781B4B39B",
      "imageFilename": "6cc105c3-fc92-40fd-a29c-da3d4ed3228b.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "76F4466E-3CA5-4422-A7A4-2F312145AF17",
      "meta": {
        "id": "17519715-08AF-4784-A9FA-9C074979D5FB",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 4,
      "isMarked": true,
      "wasAddedWithClient": false,
      "description": "Laminat fehlerhaft",
      "craftsman": "EA0C45B1-17AF-40CC-BD1C-AFC17D9338A0",
      "imageFilename": "bf063b41-a2f5-468c-8b1d-69648d37940f.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Paul Schweighauser (Davoser Ingenieure AG (DIAG))"
        },
        "review": null
      },
      "position": {
        "x": 0.8,
        "y": 0.3,
        "zoomScale": 0.5
      },
      "map": "1C2F2551-ECD7-426E-B3FB-09A8E2A00902",
      "meta": {
        "id": "17564BCC-75AE-4FA6-AEBC-EB6C4F6DB6DA",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 17,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand",
      "craftsman": "8B89443F-D369-4998-B985-FA9862A6B416",
      "imageFilename": "64caec99-74e4-45f7-93f3-d9f63538aa59.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "58141DC5-7B76-4A0C-8450-68B53838934C",
      "meta": {
        "id": "1D4A991A-4686-4B88-9FE1-1E0CBB0651B3",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 8,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Steckdose eingedrückt",
      "craftsman": "333E88C9-7CF0-4F0F-A32E-050F0E0DC038",
      "imageFilename": "0469b1d1-b3a1-42da-bde5-4fea160d3537.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Thomas Kuster (Kuster + Partner AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:57+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.1,
        "y": 0.1,
        "zoomScale": 0.2
      },
      "map": "76F4466E-3CA5-4422-A7A4-2F312145AF17",
      "meta": {
        "id": "22B640B1-1372-4093-BE07-1F5EF31613FF",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 23,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand (new)",
      "craftsman": "333E88C9-7CF0-4F0F-A32E-050F0E0DC038",
      "imageFilename": "52308ec1-b3ab-44c9-8a7c-30a9d6bb911c.jpg",
      "status": {
        "registration": null,
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "76F4466E-3CA5-4422-A7A4-2F312145AF17",
      "meta": {
        "id": "2C911F3F-279A-43E7-829B-153786982407",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 11,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Löcher im Parkett",
      "craftsman": "D92600BD-653B-4351-BC61-01598BC37220",
      "imageFilename": "a2b49022-7744-4594-97b1-903b5e004293.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Alek Tobler (Kunz AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:57+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.2,
        "y": 0.2,
        "zoomScale": 0.6
      },
      "map": "4D4000B3-635E-4123-881D-A13A4F0EE6CB",
      "meta": {
        "id": "4D02AE0E-4FE4-4554-8061-75E8151E4743",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 24,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand (new)",
      "craftsman": "E3A50FC8-6F4D-437D-A95E-98CC8FDD3931",
      "imageFilename": "cb7775a9-83f3-4c99-accc-caac81bfe395.jpg",
      "status": {
        "registration": null,
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "1C2F2551-ECD7-426E-B3FB-09A8E2A00902",
      "meta": {
        "id": "60F3C74C-5A39-43B8-9A7B-63B71EDE4ABF",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 1,
      "isMarked": true,
      "wasAddedWithClient": false,
      "description": "Laminat fehlerhaft",
      "craftsman": "CBBC690A-CBFB-494B-9188-1AED2BB363EE",
      "imageFilename": "94042648-bd3b-4c19-b292-68fb4cd0c3e9.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Flurina Rüesch (Baulink AG)"
        },
        "review": null
      },
      "position": {
        "x": 0.8,
        "y": 0.3,
        "zoomScale": 0.5
      },
      "map": "4D4000B3-635E-4123-881D-A13A4F0EE6CB",
      "meta": {
        "id": "7545C248-1987-4226-B0C3-BDB5B899C1DB",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 19,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand",
      "craftsman": "EA0C45B1-17AF-40CC-BD1C-AFC17D9338A0",
      "imageFilename": "869a7008-377f-4e5c-afd4-6487151344b3.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "1C2F2551-ECD7-426E-B3FB-09A8E2A00902",
      "meta": {
        "id": "790D7BC9-DDE8-49BB-ADCD-916FFE2D3817",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 3,
      "isMarked": true,
      "wasAddedWithClient": false,
      "description": "Laminat fehlerhaft",
      "craftsman": "55E1A856-AABD-4E59-AE7C-442781B4B39B",
      "imageFilename": "0f7e64ac-299a-44d8-a5a1-e615d4e2dcf9.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Hans-Peter Hoffmann (Baulink AG)"
        },
        "review": null
      },
      "position": {
        "x": 0.8,
        "y": 0.3,
        "zoomScale": 0.5
      },
      "map": "76F4466E-3CA5-4422-A7A4-2F312145AF17",
      "meta": {
        "id": "7E976DF3-32DF-467C-BBB0-9B3620D0B3BF",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 13,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Löcher im Parkett",
      "craftsman": "BAE2336D-9D1A-4493-A92B-1FE5004AA0FF",
      "imageFilename": "00c70bb5-77cc-4578-8fda-6c50ae32f8f5.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:58+02:00",
          "author": "Rico Buchli (Kunz AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:58+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.2,
        "y": 0.2,
        "zoomScale": 0.6
      },
      "map": "76F4466E-3CA5-4422-A7A4-2F312145AF17",
      "meta": {
        "id": "7F4B82E3-DB15-404A-8533-D1B8C76B235F",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 2,
      "isMarked": true,
      "wasAddedWithClient": false,
      "description": "Laminat fehlerhaft",
      "craftsman": "8B89443F-D369-4998-B985-FA9862A6B416",
      "imageFilename": "14f7dce5-b852-42fc-b136-05464f1ffaf8.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Dominic Koch (Baulink AG)"
        },
        "review": null
      },
      "position": {
        "x": 0.8,
        "y": 0.3,
        "zoomScale": 0.5
      },
      "map": "58141DC5-7B76-4A0C-8450-68B53838934C",
      "meta": {
        "id": "A5E2539C-6D6B-48B7-A728-58750DFC67E8",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 9,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Steckdose eingedrückt",
      "craftsman": "E3A50FC8-6F4D-437D-A95E-98CC8FDD3931",
      "imageFilename": "6f7e450b-86cb-41ad-baed-2d2fc2339435.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Patrick Hager (Toneatti AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:57+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.1,
        "y": 0.1,
        "zoomScale": 0.2
      },
      "map": "1C2F2551-ECD7-426E-B3FB-09A8E2A00902",
      "meta": {
        "id": "ABB71096-5501-42DD-9333-33719853950E",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 5,
      "isMarked": true,
      "wasAddedWithClient": false,
      "description": "Laminat fehlerhaft",
      "craftsman": "606CE558-DCB2-45BC-850E-540A639184D3",
      "imageFilename": "fa12f2c0-c808-4677-86e2-0f38606a5ed9.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "René Wildhaber (Wildhaber Elektroplanung AG)"
        },
        "review": null
      },
      "position": {
        "x": 0.8,
        "y": 0.3,
        "zoomScale": 0.5
      },
      "map": "E5EB2EE7-DEDC-44F3-ADC5-935A27D090AD",
      "meta": {
        "id": "B2915DC5-7476-4257-8BBA-7C26520EDC50",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 20,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand",
      "craftsman": "606CE558-DCB2-45BC-850E-540A639184D3",
      "imageFilename": "772812a9-5f46-4116-b657-8a27420457f2.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "E5EB2EE7-DEDC-44F3-ADC5-935A27D090AD",
      "meta": {
        "id": "C1EEB63D-7FD9-4CE8-B7CC-38F1EEB27D0C",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 7,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Steckdose eingedrückt",
      "craftsman": "4E28156C-A05E-43BC-8B14-C7550D31ECFB",
      "imageFilename": "3a3edc9f-ccd4-4b24-a710-3298d3a32ced.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Sandro Darms (Marco Felix AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:57+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.1,
        "y": 0.1,
        "zoomScale": 0.2
      },
      "map": "58141DC5-7B76-4A0C-8450-68B53838934C",
      "meta": {
        "id": "C2169264-2CE4-4FDC-8249-787898444047",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    },
    {
      "number": 12,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Löcher im Parkett",
      "craftsman": "043524AC-BBAF-40C9-856B-61C9503830A8",
      "imageFilename": "109026ba-cfeb-4052-9146-9cca741f981a.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:58+02:00",
          "author": "Mario Casanova (Kunz AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:58+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.2,
        "y": 0.2,
        "zoomScale": 0.6
      },
      "map": "58141DC5-7B76-4A0C-8450-68B53838934C",
      "meta": {
        "id": "C8892B9F-77B9-494D-A5B8-DDB06B3D022E",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 16,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand",
      "craftsman": "CBBC690A-CBFB-494B-9188-1AED2BB363EE",
      "imageFilename": "90d27bd3-53f2-484e-8937-4b794dcfa53e.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "4D4000B3-635E-4123-881D-A13A4F0EE6CB",
      "meta": {
        "id": "D0ACEB13-4BBE-46A3-B4C5-71444CA1B04A",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 15,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Löcher im Parkett",
      "craftsman": "E0D76132-D223-4D9D-B700-8AE397E699CF",
      "imageFilename": "df3fe13c-9f6f-4ede-9faa-165d74025faf.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:58+02:00",
          "author": "Remo Caprez (Schindler Aufzüge AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:58+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.2,
        "y": 0.2,
        "zoomScale": 0.6
      },
      "map": "E5EB2EE7-DEDC-44F3-ADC5-935A27D090AD",
      "meta": {
        "id": "D352E066-6FF0-40DA-A3A3-56F418974C54",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 21,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand (new)",
      "craftsman": "BD1B7ED6-A87E-4999-AE7E-026EC68206B1",
      "imageFilename": "aa4abaf0-ee4a-41f6-a61e-4cb1d91bb0b9.jpg",
      "status": {
        "registration": null,
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "4D4000B3-635E-4123-881D-A13A4F0EE6CB",
      "meta": {
        "id": "EA5B0718-58D1-4213-8372-4FD37F1580FF",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 14,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Löcher im Parkett",
      "craftsman": "93561805-8EA4-4FC1-AEA4-129B5E07652C",
      "imageFilename": "6384277e-ca98-4707-8178-7855261cb41f.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:58+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:58+02:00",
          "author": "Janine Bernhard (Bernhard Holzbau AG)"
        },
        "review": {
          "time": "2018-06-24T18:06:58+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.2,
        "y": 0.2,
        "zoomScale": 0.6
      },
      "map": "1C2F2551-ECD7-426E-B3FB-09A8E2A00902",
      "meta": {
        "id": "EC2D426B-2C0D-44AB-A2FA-D3306ED32E9F",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 22,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Flecken an der Wand (new)",
      "craftsman": "4E28156C-A05E-43BC-8B14-C7550D31ECFB",
      "imageFilename": "7e362d99-7d03-44f2-9613-7654c3e6d19f.jpg",
      "status": {
        "registration": null,
        "response": null,
        "review": null
      },
      "position": {
        "x": 0.5,
        "y": 0.3,
        "zoomScale": 1
      },
      "map": "58141DC5-7B76-4A0C-8450-68B53838934C",
      "meta": {
        "id": "F1D5FA5F-DB1A-460D-A530-F91D39494311",
        "lastChangeTime": "2018-06-24T18:06:58+02:00"
      }
    },
    {
      "number": 6,
      "isMarked": false,
      "wasAddedWithClient": false,
      "description": "Steckdose eingedrückt",
      "craftsman": "BD1B7ED6-A87E-4999-AE7E-026EC68206B1",
      "imageFilename": "af7a0e90-c212-4dd4-b59c-0779953e896f.jpg",
      "status": {
        "registration": {
          "time": "2018-06-24T13:06:57+02:00",
          "author": "Julian Dunskus"
        },
        "response": {
          "time": "2018-06-24T16:06:57+02:00",
          "author": "Remo Collenberg (Remo Collenberg)"
        },
        "review": {
          "time": "2018-06-24T18:06:57+02:00",
          "author": "Julian Dunskus"
        }
      },
      "position": {
        "x": 0.1,
        "y": 0.1,
        "zoomScale": 0.2
      },
      "map": "4D4000B3-635E-4123-881D-A13A4F0EE6CB",
      "meta": {
        "id": "F7139EDA-4848-489E-A62D-86D6FDAB1F9A",
        "lastChangeTime": "2018-06-24T18:06:57+02:00"
      }
    }
  ],
  "removedIssueIDs": [],
  "changedUser": {
    "authenticationToken": "uRekOUnfs9zBKqEWArEd",
    "givenName": "Julian",
    "familyName": "Dunskus",
    "meta": {
      "id": "F3B186BC-1694-407F-BB92-7E49A49CFD06",
      "lastChangeTime": "2018-06-24T18:06:52+02:00"
    }
  }
}
""".data(using: .utf8)!
