$graph:
- class: Workflow
  label: This application generates Sentinel-2 RGB composites
  doc: This application generates a Sentinel-2 RGB composite over an area of interest with selected bands

  id: s2-composites

  requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement

  inputs: 

    products: 
      type: Directory[]
      label: Sentinel-2 input references
      doc: Sentinel-2 Level-1C or Level-2A input references
    red:
      type: string
      label: Sentinel-2 band for red channel
      doc: Sentinel-2 band for red channel
    green:
      type: string
      label: Sentinel-2 band for green channel
      doc: Sentinel-2 band for green channel
    blue:
      type: string
      label: Sentinel-2 band for blue channel
      doc: Sentinel-2 band for blue channel
    bbox:
      type: string
      label: Area of interest expressed as a bounding bbox
      doc: Area of interest expressed as a bounding bbox
    proj:
      type: string
      label: EPSG code 
      doc: Projection EPSG code for the bounding box coordinates
      default: "EPSG:4326"

  outputs:
    wf_results:
      outputSource:
      - node_rgb/results
      type: Directory[]

  steps:
    
    node_rgb:

      run: "#s2-compositer"

      in: 
        product: products
        red: red
        green: green
        blue: blue
        bbox: bbox
        proj: proj

      out:
      - results

      scatter: product
      scatterMethod: dotproduct 

- class: Workflow
  label: This sub-workflow generates a Sentinel-2 RGB composite 
  doc: This sub-workflow generates a Sentinel-2 RGB composite over an area of interest 
  id: s2-compositer

  requirements:
  - class: ScatterFeatureRequirement
  - class: InlineJavascriptRequirement

  inputs:
    product:
      type: Directory
      label: Sentinel-2 input reference 
      doc: Sentinel-2 Level-1C or Level-2A input reference
    red:
      type: string
      label: Sentinel-2 band for red channel
      doc: Sentinel-2 band for red channel
    green:
      type: string
      label: Sentinel-2 band for green channel
      doc: Sentinel-2 band for green channel
    blue:
      type: string
      label: Sentinel-2 band for blue channel
      doc: Sentinel-2 band for blue channel
    bbox:
      type: string
      label: Area of interest expressed as a bounding bbox
      doc: Area of interest expressed as a bounding bbox
    proj:
      type: string
      label: EPSG code 
      doc: Projection EPSG code for the bounding box coordinates
      default: "EPSG:4326"

  outputs:
    results:
      outputSource:
      - node_composite/rgb_composite
      type: Directory
      
  steps:

    node_bands:

      run: "#arrange_bands"

      in: 
        red: red
        green: green
        blue: blue

      out:
        - bands 

    node_crop:

      run: "#crop-cl"

      in:
        product: product 
        band: node_bands/bands
        bbox: bbox
        epsg: proj

      out:
        - cropped_tif

      scatter: band
      scatterMethod: dotproduct 

    node_composite:

      run: "#composite-cl"

      in:
        cropped_tifs:
          source:  node_crop/cropped_tif
        lineage: product  
        bbox: bbox

      out:
        - rgb_composite

- class: CommandLineTool

  id: crop-cl

  requirements:
    DockerRequirement: 
      dockerPull: terradue/crop-container

  baseCommand: crop
  arguments: []

  inputs: 
    product: 
      type: Directory
      inputBinding:
        position: 1
    band: 
      type: string
      inputBinding:
        position: 2
    bbox: 
      type: string
      inputBinding:
        position: 3
    epsg:
      type: string
      inputBinding:
        position: 4
  
  outputs:
    cropped_tif:
      outputBinding:
        glob: '*.tif'
      type: File

- class: CommandLineTool

  id: composite-cl

  requirements:
    DockerRequirement: 
      dockerPull: terradue/composite-container
    InlineJavascriptRequirement: {}

  baseCommand: composite
  arguments: 
  - $( inputs.cropped_tifs[0].path )
  - $( inputs.cropped_tifs[1].path )
  - $( inputs.cropped_tifs[2].path )

  inputs: 
    cropped_tifs: 
      type: File[]
    lineage: 
      type: Directory
      inputBinding:
        position: 4
    bbox: 
      type: string
      inputBinding:
        position: 5
        
  outputs:
    rgb_composite:
      outputBinding:
        glob: .
      type: Directory

- class: ExpressionTool

  id: arrange_bands 
  
  inputs:
    red:
      type: string
    green:
      type: string
    blue:
      type: string
 
  outputs:
    bands:
      type: string[]

  expression: |
    ${ 
      return { "bands": [ inputs.red, inputs.green, inputs.blue ] } 
    }

$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.3
schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf

cwlVersion: v1.0
