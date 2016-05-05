set svgtemplate {<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100%" height="100%" viewport="0 0 2000 2000">
    <script xlink:href="SVGPan.js"/>
    <polygon style="fill:%BACKGROUND%;stroke:none" points="0,0 0,2000 10000,2000 10000,0 0,0"/>
    <g id="displaycenter" opacity="0.0">
        <polygon style="fill:%BACKGROUND%;stroke:none" points="100,1000 100,2000 2000,2000 2000,100 100,100" onmouseover="displayinterface('none',0.0)"/>
    </g>    
    <g id="viewport">
       %CONTENT%
    </g>
    </svg>
}

set itemtemplate {          <g id="%ID%" class="%CLASS%">
            <title>%TITLE%</title>
    <path style="fill:%FILLCOLOR%;fill-opacity:%FILLOPACITY%;stroke:%STROKECOLOR%;stroke-opacity:%STROKEOPACITY%;stroke-width:%STROKEWIDTH%" d="%POINTS%"  title="%ID%"/>
        </g>
}
