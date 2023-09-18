unit modTypes;

interface

uses
  System.Types;

type

  TUserRights = record
    AbAdd: Boolean; // rght_Abonents_add = 31;
    AbEdit: Boolean;   // rght_Abonents_edit = 33;
    AbAddSrv: Boolean; // rght_Abonents_AddSrv = 34;
  end;

  TmyTypeSettingsData = record
    status: string;
    login: string;
    password: string;
    autoEnter: string;
    gpsInterval: integer;
    company: string;
    validURL: string;
    validURL_date: TDate;
  end;

  //
  TmyTypeAuthItem = record
    user: string;
    gps: integer;
    Rights: TUserRights;
  end;

  TmyTypeAuth = record
    status: string;
    struct: TArray<TmyTypeAuthItem>;
  end;
  // ...

  //
  TmyTypeStreetHouseItem = record
    id: integer;
    name: string;
  end;

  TmyTypeStreetHouse = record
    status: string;
    struct: TArray<TmyTypeStreetHouseItem>;
  end;
  // ...

  //
  TmyTypeHouseInfoEquipment = record
    id: integer;
    // [alias('type')]
    e_type: integer;
    name: string;
    notice: string;
  end;

  TmyTypeHouseInfoCircuit = record
    id: integer;
    name: string;
    notice: string;
  end;

  TmyTypeHouseInfoItem = record
    id: integer;
    name: string;
    chair: string;
    chair_phone: string;
    bid_count: integer;
    equipment: TArray<TmyTypeHouseInfoEquipment>;
    circuit: TArray<TmyTypeHouseInfoCircuit>;
  end;

  TmyTypeHouseInfo = record
    status: string;
    struct: TmyTypeHouseInfoItem;
  end;
  // ...

  //
  TmyTypeHouseCustomersItem = record
    id: integer;
    fio: string;
    balance: string;
    flat: string;
    porch: string;
    floor: string;
    info: string;
    color: String;
    connected: integer;
  end;

  TmyTypeHouseCustomers = record
    status: string;
    struct: TArray<TmyTypeHouseCustomersItem>;
  end;
  // ...

  //
  TmyTypeCustomerService = record
    service_id: integer;
    name: string;
    tarif: string;
  end;

  TmyTypeCustomerEquipment = record
    id: integer;
    name: string;
    // [alias('type')]
    e_type: string;
    mac: string;
    parent_id: integer;
    parent_name: string;
    port: string;
  end;

  {
    TmyTypeCustomerCoefficient = record
    id: integer;
    value: integer;
    name: string;
    end;
  }

  TmyTypeCustomerDiscount = record
    id: integer;
    srv_id: integer;
    name: string;
    date_from: string;
    date_to: string;
    value: string;
  end;

  TmyTypeCustomerItem = record
    id: integer;
    balance: string;
    account: string;
    surname: string;
    firstname: string;
    midlename: string;
    street: string;
    house: string;
    house_id: integer;
    flat: string;
    phones: string;
    passport_num: string;
    passport_reg: string;
    color: string;
    notice: string;
    services: TArray<TmyTypeCustomerService>;
    equipment: TArray<TmyTypeCustomerEquipment>;
    discount: TArray<TmyTypeCustomerDiscount>;
  end;

  TmyTypeCustomer = record
    status: string;
    struct: TArray<TmyTypeCustomerItem>;
  end;
  // ...

  //
  TmyTypeEqipmentAttr = record
    name: string;
  end;

  TmyTypeEqipmentPorts = record
    id: integer;
    name: string;
    port: string;
    ip: string;
    // [alias('type')]
    e_type: integer;
    on_srv: integer;
  end;

  TmyTypeEqipmentItem = record
    id: integer;
    name: string;
    place: string;
    house_id: integer;
    ip: string;
    mac: string;
    // [alias('type')]
    e_type: integer;
    notice: string;
    parent_id: integer;
    parent_aderss: string;
    parent_name: string;
    parent_ip: string;
    parent_port: string;
    parent_type: integer;
    attributes: TArray<TmyTypeEqipmentAttr>;
    ports: TArray<TmyTypeEqipmentPorts>;
  end;

  TmyTypeEqipmentInfo = record
    status: string;
    struct: TmyTypeEqipmentItem;
  end;
  // ...

  //
  TmyTypeContactListItem = record
    name: string;
    phone: string;
  end;

  TmyTypeContactsList = record
    status: string;
    struct: TArray<TmyTypeContactListItem>;
  end;
  // ...

  //
  TmyTypeBidListItem = record
    id: integer;
    plan_str: string;
    plan_date: integer;
    color: string;
    type_name: string;
    adress: string;
    content: string;
    whose: integer;
  end;

  TmyTypeBidList = record
    status: string;
    struct: TArray<TmyTypeBidListItem>;
  end;
  // ...

  //
  TmyTypeBidInfoItem = record
    id: integer;
    plan_str: string;
    plan_date: integer;
    color: string;
    type_name: string;
    adress: string;
    content: string;
    whose: integer;
    house_id: integer;
    phones: string;
    customer_id: integer;
    balance: string;
    account: string;
    fio: string;
    services: TArray<TmyTypeCustomerService>;
  end;

  TmyTypeBidInfo = record
    status: string;
    struct: TmyTypeBidInfoItem;
  end;
  // ...

  //
  TmyTypeMaterialItem = record
    id: integer;
    name: string;
    rest: string;
    int: integer;
    wh_id: integer;
  end;

  TmyTypeMaterials = record
    status: string;
    struct: TArray<TmyTypeMaterialItem>;
  end;
  // ...

  //
  TmyTypeLocalBidPhotoItem = record
    data: string;
  end;

  TmyTypeLocalBidMaterials = record
    ids: string;
    counts: string;
    whids: string;
  end;

  TmyTypeLocalBid = record
    status: string;
    id: integer;
    result: integer;
    resultText: string;
    unix_dt: integer;
    photos: TArray<TmyTypeLocalBidPhotoItem>;
    materials: TmyTypeLocalBidMaterials;
  end;

  // ...

  //
  TmyTypePromoItem = record
    title: string;
    body: string;
    url: string;
  end;

  TmyTypePromoList = record
    status: string;
    struct: TArray<TmyTypePromoItem>;
  end;
  // ...

  //
  TmyTypeLinkToItem = record
    id: integer;
    name: string;
  end;

  TmyTypeLinkTo = record
    status: string;
    struct: TArray<TmyTypeLinkToItem>;
  end;
  // ...

  //
  TmyTypeDiscountItem = record
    id: integer;
    name: string;
  end;

  TmyTypeDiscount = record
    status: string;
    struct: TArray<TmyTypeDiscountItem>;
  end;
  // ...

  TmyStoreService = record
    service_id: integer;
    name: string;
    price: string;
    onList_id: integer;
    onList_name: string;
    date: TDateTime;
    notice: string;
  end;

  TmyStoreEquipment = record
    equipment_id: integer;
    name: string;
    ip: string;
    mac: string;
    port: integer;
    notice: string;
  end;

  TmyStoreDiscount = record
    name: string;
    from_date: TDateTime;
    to_date: TDateTime;
    discount_id: integer;
    sum: single;
    notice: string;
  end;

  // передача данных между формами
  TmyStoreData = record
  public
    class var FService: TmyStoreService;
    class var FEquipment: TmyStoreEquipment;
    class var FDiscount: TmyStoreDiscount;
  end;

  //
  TmyTypeNewCustomer = record
    customer_id: integer;
    house_id: integer;
    flat: string;
    secondname: string;
    name: string;
    thirdname: string;
    passport_num: string;
    passport_reg: string;
    desc: string;
    new_services: TArray<TmyStoreService>;
    new_equipments: TArray<TmyStoreEquipment>;
    new_discounts: TArray<TmyStoreDiscount>;
  end;

  //
  TmyTypeCustomServicesOnlist = record
    on_id: integer;
    name: string;
  end;

  TmyTypeCustomServicesServices = record
    service_id: integer;
    name: string;
    onlist: TArray<TmyTypeCustomServicesOnlist>;
  end;

  TmyTypeCustomServices = record
    status: string;
    struct: TArray<TmyTypeCustomServicesServices>;
  end;
  // ...

  TmyTypeBookmarkItem = record
    name: string;
    form: string;
    id: integer;
  end;

  TmyTypeBookmarks = record
    status: string;
    struct: TArray<TmyTypeBookmarkItem>;
  end;

implementation

end.
