pageextension 90116 "ACS Purchase Price List Ext" extends "Purchase Price List"
{
	layout
	{
		addlast(Content)
		{
			field("ACS Vendor Name"; Rec."ACS Vendor Name")
			{
				ApplicationArea = All;
				Caption = 'Vendor Name';
				ToolTip = 'Specifies the vendor name from the vendor master.';
			}
		}
	}
}
