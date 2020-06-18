public with sharing class ContactListController {
    public String cordovaBundle {
        public get{ 
            String userAgent = ApexPages.currentPage().getHeaders().get('USER-AGENT');

            if(userAgent.contains('android')) {
                return 'cordovaandroid';
            } else {
                return 'cordovaios';
            }
        }
        private set;
    }
}
