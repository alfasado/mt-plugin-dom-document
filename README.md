# DOMDocument plugin for Movable Type

This plugin provides some DOM methods in MTML\.

* Author:: Alfasado Inc.
* Website:: http://alfasado.net/
* Copyright:: Copyright 2015 Alfasado Inc.
* License:: MIT-License

\* This plugin does not support dynamic publishing\.

## Function tags:

### MTGetElementById

Get element by 'id' attribute\.

### MTGetElementsByTagName

Get elements by 'tagName' attribute\. You can specify the index of the node to the second argument\(ex\. tag\_name="Entries","0"\)\.

### MTGetElementsByName

Get elements by 'name' attribute\. You can specify the index of the node to the second argument\.

### MTGetElementsByClassName

Get elements by 'class' attribute\. You can specify the index of the node to the second argument\.

### MTSetAttribute

Set attributes to specified node\. The 'attribute' attribute you will specify an array or hash\.

### MTRemoveAttribute

Remove attributes to specified element\. If you do not specify a name attribute, and then delete all of the attributes\.

### MTCreateElement

Create MT::Template::Node object specify tag attribute\. The 'attribute' attribute you will specify an array or hash\.

### MTCreateTextNode

Create MT::Template::Node\(Text node\) object specify text attribute\.

### MTAppendChild

Append node to specified node\. The 'node' attribute you will specify an array\.

### MTInsertAfter

Insert node after specified node\. The 'node' attribute you will specify an array\.

### MTInsertBefore

Insert node before specified node\. The 'node' attribute you will specify an array\.

### MTGetInnerHTML

Output innerHTML of specified node\. 

### MTRenderNode

Build specified node\.

## Block tags:

### MTSetInnerHTML

Set innerHTML of specified node\. 

### MTSetRawTemplate

Set raw template to template var\.

## Example:

    <mt:getElementById id="entries_container" setvar="entries_container">
    <mt:removeAttribute name="id" node="entries_container">
    <mt:setAttribute node="entries_container" attributes="include_blogs","all">
    <mt:createElement tag="Pages" attributes="include_blogs","all" setvar="pages_container">
    
    <mt:setInnerHTML node="pages_container">
        <mt:If name="__first__"><ul></mt:If>
            <li><mt:PageTitle></li>
        <mt:If name="__last__"></ul></mt:If>
    </mt:setInnerHTML>
    
    <mt:RenderNode node="pages_container">
    
    <mt:insertAfter node="entries_container","pages_container">
    
    <mt:Entries id="entries_container">
        <mt:If name="__first__"><ul></mt:If>
            <li><mt:EntryTitle></li>
        <mt:If name="__last__"></ul></mt:If>
    </mt:Entries>
    
    <mt:SetVarTemplate name="template_entries">
    <mt:Unless id="entries_block">
        <mt:Entries>
            <mt:If name="__first__"><ul></mt:If>
                <li><mt:EntryTitle></li>
            <mt:If name="__last__"></ul></mt:If>
        </mt:Entries>
    </mt:Unless>
    </mt:SetVarTemplate>
    
    <mt:SetHashVars name="attributes">
        include_blogs=all
    </mt:SetHashVars>
    
    <mt:getElementsByTagName tag="Entries","0" template="template_entries" setvar="tag_entries">
    
    <mt:setAttribute node="tag_entries" attributes="$attributes">
    
    <mt:getElementById template="template_entries" id="entries_block" setvar="tag_unless">
    <mt:appendChild node="tag_unless","pages_container">
    
    <mt:Var name="template_entries">

    <mt:SetRawTemplate name="template_pages">
    <mt:Pages pointer>
        <mt:If name="__first__"><ul></mt:If>
            <li><mt:PageTitle></li>
        <mt:If name="__last__"></ul></mt:If>
    </mt:Pages>
    </mt:SetRawTemplate>
    
    <mt:Var name="template_pages" replace="pointer",'include_blogs="all"' setVar="template_pages">
    <mt:Var name="template_pages" replace="Pages","Entries" setVar="template_pages">
    <mt:Var name="template_pages" replace="Page","Entry" setVar="template_pages">
    
    <mt:Var name="template_pages" mteval="1">