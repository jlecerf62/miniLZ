
locals {
  parent_compartment_ocid = coalesce(var.deployment_compartment_ocid, var.tenancy_ocid)
}

resource "oci_identity_compartment" "unsecure_compartment" {
  #Required
  compartment_id = local.parent_compartment_ocid
  description    = "Non-secured/Public compartment"
  name           = "non-secured_compartment"
}

########################################### Security Zone

resource "oci_identity_compartment" "secure_compartment" {
  #Required
  compartment_id = local.parent_compartment_ocid
  description    = "secure compartment"
  name           = "secured_compartment"

}

resource "oci_cloud_guard_security_zone" "secure_security_zone" {
  #Required
  compartment_id          = oci_identity_compartment.secure_compartment.id
  display_name            = "Secured/Private compartment"
  security_zone_recipe_id = oci_cloud_guard_security_recipe.custom_security_recipe.id
  description             = "Secured Compartment"
}

resource "oci_cloud_guard_security_recipe" "custom_security_recipe" {
  #custom recipe removes the vault encryption requirement
  compartment_id = local.parent_compartment_ocid
  display_name   = "Custom security zone recipe"
  security_policies = [
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaadhzmdbzaemersmvdahgtc5dbc4bf7l2rlsi6aaqwgq5ywokt4nrq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaodtmgz53fekqtbnxrgzf32p4obyph2qka3szvzd433isc34y3w4a",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaf45c2imtiuyxbccuwrh3s7is5lokpx5ksr4heu46c6mz6k35dsqa",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaa5qtljtbaeacnhfhr7hfs5nd3jp6jin6grbdgf6izkf4ukxmatjpa",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaa6oycc62uuvpi6oddkzku6x2vzhraud7ynkbdeols5i4khwroklva",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaauvfkentmqda6mq7lxekkstjpe7kwgmrpkadzt7krhrt66tliourq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaa544n6cyqrq6tato53ohh7vcz523af5dtuz6x54efhs6mb7bcw54a",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaay32fadjsdgsytdpyn4busugqftko2shttseljqbagapngiatxepa",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaa2lfkaypfwyykhbz65zlgc4lvypl64axzhnsqmegllgiyxbweruya",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaah3k66efqfgo5ccjgvtkwbfpzj5yjajmw7vt5eub6ma4jp6su55zq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaqlpaf5tc3xfqdzdw2rtx7hk4ifywzml3eh3upspeh4s6x4epaskq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaxou4266jlusvklor34czqvloa64k5dsok5cejug2bxi2jvqy32zq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaajscm24dhll5wk65k6q4mmkopiykpqrumtururitjaxk3j4ibe3ua",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaol3pxbbikegih24c7l4um7wqeeun2dpkvgm3izz5syf755xfscgq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaak5wxfr2r6kxmtd6bq6hqhyywfkj6pcnl74g3iui6qnlq7rof4ezq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaabs6kboflsfan2lihfnodhbeb75r4nxiolhlobvj6vqclx6j5yyha",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaw6v2nz4unovq3joqk6pguxpaqriws2vzd7gvpldgai47tl72wseq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaa5ocyo7jqjzgjenvccch46buhpaaofplzxlp3xbxfcdwwk2tyrwqa",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaawol5fz6qkrkxm5ui7n3car44e5wbs54thnku2hjxwaedi5ee6htq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaauoi2xnbusvfd4yffdjaaazk64gndp4flumaw3r7vedwndqd6vmrq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaat5zxcpcy6vrl2xxcohi7o64vezhkwcp2ixbtreapdq4uowdu7nqq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaepqj6x3jkkprubit2pudh6f3oyc3zyj2ycrmcox44duszghlo4iq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaegi6cweu5jqwipqhj5quz4pebfd76djed4lfogslzuawqavkrsjq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaarkvvuzwtc6xwwr57zg6fymgkco3lbt35c7r4lnahw4ab5i3vkbrq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaapvmbf77sfr43sryhmdwoztbjck2h5fvsm5kyoc4zomfju6243oja",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaazhmr3fyx6xwutuqpiddvfk3wqnj6kxxtiyohl3v47xzpcm77uwfa",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaaby4h5ojgqrbtajfvtx2qu5yp3l2u4r6g3ai2nxw4bgywusm473xa",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaakbmbc7p52m5ynbkb2mg2ogkelkpe5n5pty4qpavsegbbnoypys5q",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaauhuzsidaju3mwy3llsetvm3dlc6ftel65ielfu7h4hg6q2cfsrxa",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaawec56szedvf6hogbbnu7cxywm4xkmta53wuo7lenceiqyr4bx5hq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaao5qwdxigf7jfnstvzlexk4fnwojlnwidfdi3o25ublxop536qgmq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaak2x2aomzhqoeg2bf4zgqyr3bg2ppsfhupn2xvu66zpuz7kbvae5a",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaauah5cz3vxzpdvw4uz32hcgcmhogvuhacgyc7z3al42tfjey46eea",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaawebiliesbgzdguac5m5u332oj66afaab6ruovydpsdoexloguweq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaadldlomr5moxliz3jyt4guuwoci72ysf3vplkpl4z22a46xtdhmfq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaa6j7b5bf3ytsno7a45r7xupqt2q342q2hlecnf7fgqpkq67stakda",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaa7ld4u7j4c3tifkutsbxzgw4ija76irnjiy2c6egd5netnspcyayq",
    "ocid1.securityzonessecuritypolicy.oc1..aaaaaaaanvmmvw2bll4zyaisxct4mi5fxsmw7ncgfclxxmgh3qtsq5mgumga"
  ]
  description = "custom security zone recipe without OCI vault encryption requirement"
}

################################################# Cloudguard
